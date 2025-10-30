#!/usr/bin/env python3
"""
ComfyUI Package Compatibility Analyzer

Analyzes package versions across current_working_requirements.txt,
and all custom_nodes subdirectories to identify conflicts and suggest compatible versions.
"""

import os
import re
from pathlib import Path
from collections import defaultdict
from typing import Dict, Set, List, Tuple, Optional
import argparse


class PackageVersion:
    """Represents a package with its version and source file."""
    
    def __init__(self, name: str, version: str, source: str, line: str):
        self.name = name.lower()  # Normalize package names
        self.version = version
        self.source = source
        self.line = line.strip()
        
    def __repr__(self):
        return f"{self.name}=={self.version} (from {self.source})"


class PackageAnalyzer:
    """Analyzes package compatibility across multiple requirements files."""
    
    def __init__(self, base_dir: str = "."):
        self.base_dir = Path(base_dir)
        self.packages: Dict[str, List[PackageVersion]] = defaultdict(list)
        self.reference_packages: Dict[str, PackageVersion] = {}
        
    def parse_requirements_line(self, line: str, source: str) -> Optional[PackageVersion]:
        """Parse a single line from requirements.txt file."""
        line = line.strip()
        
        # Skip empty lines and comments
        if not line or line.startswith('#'):
            return None
            
        # Skip git URLs and other special cases for now (store separately if needed)
        if line.startswith('git+') or line.startswith('http'):
            return None
            
        # Handle package==version format
        match = re.match(r'^([a-zA-Z0-9_\-\.]+)\s*==\s*([^\s;]+)', line)
        if match:
            name, version = match.groups()
            # Clean up version (remove any trailing markers like +cu128)
            version_clean = re.sub(r'\+.*$', '', version)
            return PackageVersion(name, version_clean, source, line)
        
        # Handle other operators (>=, <=, ~=, etc.) - record but note they're flexible
        match = re.match(r'^([a-zA-Z0-9_\-\.]+)\s*([><=~!]+)\s*([^\s;]+)', line)
        if match:
            name, op, version = match.groups()
            version_clean = re.sub(r'\+.*$', '', version)
            return PackageVersion(name, version_clean, source, line)
            
        # Handle package names without version specifiers
        match = re.match(r'^([a-zA-Z0-9_\-\.]+)(?:\s|$)', line)
        if match:
            name = match.group(1)
            return PackageVersion(name, "any", source, line)
            
        return None
    
    def load_requirements_file(self, filepath: Path) -> List[PackageVersion]:
        """Load and parse a requirements.txt file."""
        packages = []
        
        try:
            with open(filepath, 'r', encoding='utf-8') as f:
                for line_num, line in enumerate(f, 1):
                    pkg = self.parse_requirements_line(line, str(filepath))
                    if pkg:
                        packages.append(pkg)
        except Exception as e:
            print(f"⚠️  Error reading {filepath}: {e}")
            
        return packages
    
    def load_reference_files(self):
        """Load win-requirements.txt and requirements-uv.txt as reference."""
        print("📚 Loading reference files...")
        
        # Load current_working_requirements.txt
        win_req = self.base_dir / "current_working_requirements.txt"
        if win_req.exists():
            print(f"  ✓ Loading {win_req.name}")
            packages = self.load_requirements_file(win_req)
            for pkg in packages:
                # Win requirements take precedence
                if pkg.name not in self.reference_packages:
                    self.reference_packages[pkg.name] = pkg
                self.packages[pkg.name].append(pkg)
        else:
            print(f"  ⚠️  {win_req.name} not found")
        
        
        print(f"  📦 Loaded {len(self.reference_packages)} reference packages\n")
    
    def scan_custom_nodes(self):
        """Scan all custom_nodes subdirectories for requirements.txt files."""
        print("🔍 Scanning custom_nodes directory...")
        
        custom_nodes_dir = self.base_dir / "custom_nodes"
        
        if not custom_nodes_dir.exists():
            print(f"  ⚠️  custom_nodes directory not found at {custom_nodes_dir}")
            return
        
        node_count = 0
        req_count = 0
        
        for node_dir in sorted(custom_nodes_dir.iterdir()):
            if node_dir.is_dir():
                node_count += 1
                req_file = node_dir / "requirements.txt"
                
                if req_file.exists():
                    req_count += 1
                    print(f"  ✓ Found requirements in: {node_dir.name}")
                    packages = self.load_requirements_file(req_file)
                    
                    for pkg in packages:
                        self.packages[pkg.name].append(pkg)
        
        print(f"\n  📊 Scanned {node_count} custom nodes")
        print(f"  📄 Found {req_count} requirements.txt files\n")
    
    def analyze_conflicts(self) -> Dict[str, Dict]:
        """Analyze package versions and identify conflicts."""
        print("🔬 Analyzing package versions...\n")
        
        conflicts = {}
        
        for pkg_name, versions in sorted(self.packages.items()):
            # Get unique versions
            unique_versions = {}
            for v in versions:
                if v.version not in unique_versions:
                    unique_versions[v.version] = []
                unique_versions[v.version].append(v.source)
            
            # If there's more than one version, it's a potential conflict
            if len(unique_versions) > 1:
                reference_version = self.reference_packages.get(pkg_name)
                
                conflicts[pkg_name] = {
                    'versions': unique_versions,
                    'reference': reference_version,
                    'all_entries': versions
                }
        
        return conflicts
    
    def print_report(self, conflicts: Dict[str, Dict]):
        """Print a detailed compatibility report."""
        print("=" * 80)
        print("📋 PACKAGE COMPATIBILITY REPORT")
        print("=" * 80)
        print()
        
        if not conflicts:
            print("✅ No conflicts found! All packages have consistent versions.\n")
            return
        
        print(f"⚠️  Found {len(conflicts)} packages with version conflicts:\n")
        
        for pkg_name, info in sorted(conflicts.items()):
            reference = info['reference']
            versions = info['versions']
            
            print("─" * 80)
            print(f"📦 Package: {pkg_name}")
            print()
            
            if reference:
                print(f"  🎯 REFERENCE VERSION: {reference.version}")
                print(f"     Source: {reference.source}")
                print()
            else:
                print(f"  ⚠️  NO REFERENCE VERSION (not in win-requirements.txt or requirements-uv.txt)")
                print()
            
            print("  📊 All versions found:")
            for version, sources in sorted(versions.items(), key=lambda x: x[0]):
                marker = "✓" if reference and version == reference.version else "✗"
                print(f"     {marker} {version}")
                for source in sources:
                    source_name = Path(source).relative_to(self.base_dir)
                    print(f"        - {source_name}")
            
            print()
            
            if reference:
                print(f"  💡 RECOMMENDATION: Update all custom nodes to use version {reference.version}")
                print(f"     Add to requirements.txt: {pkg_name}=={reference.version}")
            else:
                # Suggest most common version
                version_counts = {v: len(s) for v, s in versions.items()}
                most_common = max(version_counts.items(), key=lambda x: x[1])
                print(f"  💡 RECOMMENDATION: Most common version is {most_common[0]} (used in {most_common[1]} files)")
                print(f"     Consider adding to reference files and using: {pkg_name}=={most_common[0]}")
            
            print()
        
        print("=" * 80)
        print()
    
    def generate_update_suggestions(self, conflicts: Dict[str, Dict]) -> List[str]:
        """Generate specific update suggestions for each custom node."""
        print("🔧 SUGGESTED UPDATES BY CUSTOM NODE")
        print("=" * 80)
        print()
        
        # Group by custom node
        node_updates = defaultdict(list)
        
        for pkg_name, info in conflicts.items():
            reference = info['reference']
            
            if not reference:
                continue
            
            for entry in info['all_entries']:
                source_path = Path(entry.source)
                
                # Check if it's a custom node
                if 'custom_nodes' in source_path.parts:
                    # Extract node name
                    parts = source_path.parts
                    idx = parts.index('custom_nodes')
                    if idx + 1 < len(parts):
                        node_name = parts[idx + 1]
                        
                        if entry.version != reference.version:
                            node_updates[node_name].append({
                                'package': pkg_name,
                                'current': entry.version,
                                'recommended': reference.version,
                                'file': source_path
                            })
        
        if not node_updates:
            print("✅ No updates needed for custom nodes!\n")
            return []
        
        suggestions = []
        
        for node_name, updates in sorted(node_updates.items()):
            print(f"📁 {node_name}")
            print(f"   File: custom_nodes/{node_name}/requirements.txt")
            print(f"   Updates needed: {len(updates)}")
            print()
            
            for update in updates:
                suggestion = f"   {update['package']}: {update['current']} → {update['recommended']}"
                print(suggestion)
                suggestions.append(f"{node_name}: {update['package']}=={update['recommended']}")
            
            print()
        
        print("=" * 80)
        print()
        
        return suggestions
    
    def run_analysis(self):
        """Run the complete analysis workflow."""
        print("\n" + "=" * 80)
        print("🚀 ComfyUI Package Compatibility Analyzer")
        print("=" * 80)
        print()
        
        # Load reference files
        self.load_reference_files()
        
        # Scan custom nodes
        self.scan_custom_nodes()
        
        # Analyze conflicts
        conflicts = self.analyze_conflicts()
        
        # Print report
        self.print_report(conflicts)
        
        # Generate suggestions
        suggestions = self.generate_update_suggestions(conflicts)
        
        # Summary
        print("📊 SUMMARY")
        print("=" * 80)
        print(f"Total packages analyzed: {len(self.packages)}")
        print(f"Packages with conflicts: {len(conflicts)}")
        print(f"Reference packages: {len(self.reference_packages)}")
        print()
        
        if conflicts:
            print("Next steps:")
            print("1. Review the conflicts and recommendations above")
            print("2. Update custom node requirements.txt files with recommended versions")
            print("3. Run 'pip check' to verify no dependency conflicts")
            print("4. Test ComfyUI to ensure all nodes load successfully")
        else:
            print("✅ All packages are compatible! You're good to go.")
        
        print()


def main():
    parser = argparse.ArgumentParser(
        description="Analyze package compatibility for ComfyUI custom nodes"
    )
    parser.add_argument(
        "--dir",
        default=".",
        help="Base directory containing requirements files and custom_nodes folder (default: current directory)"
    )
    
    args = parser.parse_args()
    
    analyzer = PackageAnalyzer(args.dir)
    analyzer.run_analysis()


if __name__ == "__main__":
    main()
