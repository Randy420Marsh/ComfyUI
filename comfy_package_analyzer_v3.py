#!/usr/bin/env python3
"""
ComfyUI Package Compatibility Analyzer

Analyzes package versions across good-uv-requirements.txt, 
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
        """Load good-uv-requirements.txt"""
        print("📚 Loading reference files...")
        
        # Load current_working_requirements.txt
        win_req = self.base_dir / "good-uv-requirements.txt"
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
    
    def print_conflict_summary(self, conflicts: Dict[str, Dict]):
        """Print a summary of conflicts found."""
        print("=" * 80)
        print("📋 PACKAGE COMPATIBILITY SUMMARY")
        print("=" * 80)
        print()
        
        if not conflicts:
            print("✅ No conflicts found! All packages have consistent versions.\n")
            return
        
        print(f"⚠️  Found {len(conflicts)} packages with version conflicts\n")
        
        for pkg_name, info in sorted(conflicts.items()):
            reference = info['reference']
            versions = info['versions']
            
            if reference:
                print(f"  • {pkg_name}: {len(versions)} versions found (reference: {reference.version})")
            else:
                print(f"  • {pkg_name}: {len(versions)} versions found (no reference)")
        
        print()
    
    def generate_node_recommendations(self, conflicts: Dict[str, Dict]) -> Dict[str, List[Dict]]:
        """Generate update recommendations grouped by custom node."""
        # Group by custom node
        node_updates = defaultdict(list)
        
        for pkg_name, info in conflicts.items():
            reference = info['reference']
            
            # Determine recommended version
            if reference:
                recommended_version = reference.version
            else:
                # Use most common version if no reference
                version_counts = {}
                for entry in info['all_entries']:
                    version_counts[entry.version] = version_counts.get(entry.version, 0) + 1
                recommended_version = max(version_counts.items(), key=lambda x: x[1])[0]
            
            # Check all entries for conflicts
            for entry in info['all_entries']:
                source_path = Path(entry.source)
                
                # Check if it's a custom node
                if 'custom_nodes' in source_path.parts:
                    # Extract node name
                    parts = source_path.parts
                    idx = parts.index('custom_nodes')
                    if idx + 1 < len(parts):
                        node_name = parts[idx + 1]
                        
                        if entry.version != recommended_version:
                            node_updates[node_name].append({
                                'package': pkg_name,
                                'current': entry.version,
                                'recommended': recommended_version,
                                'has_reference': reference is not None,
                                'file': source_path
                            })
        
        return node_updates
    
    def print_node_recommendations(self, node_updates: Dict[str, List[Dict]]):
        """Print recommendations grouped by node for easy copying."""
        print("=" * 80)
        print("🔧 RECOMMENDED PACKAGE UPDATES BY CUSTOM NODE")
        print("=" * 80)
        print()
        
        if not node_updates:
            print("✅ No updates needed for custom nodes!\n")
            return
        
        print(f"Found {len(node_updates)} custom nodes with package conflicts\n")
        print("Copy and paste the recommended packages below into each node's requirements.txt\n")
        
        for node_name, updates in sorted(node_updates.items()):
            print("─" * 80)
            print(f"📁 Custom Node: {node_name}")
            print(f"   Location: custom_nodes/{node_name}/requirements.txt")
            print(f"   Packages to update: {len(updates)}")
            print()
            
            # Show current vs recommended
            print("   Current → Recommended:")
            for update in sorted(updates, key=lambda x: x['package']):
                ref_marker = "🎯" if update['has_reference'] else "📊"
                print(f"     {ref_marker} {update['package']}: {update['current']} → {update['recommended']}")
            
            print()
            print("   📋 COPY THESE LINES (recommended versions):")
            print("   " + "─" * 76)
            for update in sorted(updates, key=lambda x: x['package']):
                print(f"   {update['package']}=={update['recommended']}")
            print("   " + "─" * 76)
            print()
        
        print("=" * 80)
        print()
        print("Legend:")
        print("  🎯 = Version from reference files (win-requirements.txt or linux-requirements-uv.txt)")
        print("  📊 = Most common version (no reference available)")
        print()
    
    def export_recommendations_to_file(self, node_updates: Dict[str, List[Dict]], output_file: str = "package_updates.txt"):
        """Export recommendations to a text file for easy reference."""
        output_path = self.base_dir / output_file
        
        try:
            with open(output_path, 'w', encoding='utf-8') as f:
                f.write("ComfyUI Package Compatibility - Recommended Updates\n")
                f.write("=" * 80 + "\n\n")
                
                for node_name, updates in sorted(node_updates.items()):
                    f.write(f"Custom Node: {node_name}\n")
                    f.write(f"Location: custom_nodes/{node_name}/requirements.txt\n")
                    f.write(f"Packages to update: {len(updates)}\n\n")
                    
                    f.write("Recommended package versions:\n")
                    f.write("-" * 40 + "\n")
                    for update in sorted(updates, key=lambda x: x['package']):
                        f.write(f"{update['package']}=={update['recommended']}\n")
                    f.write("-" * 40 + "\n\n")
                    
                    f.write("Current versions:\n")
                    for update in sorted(updates, key=lambda x: x['package']):
                        f.write(f"  {update['package']}: {update['current']} → {update['recommended']}\n")
                    f.write("\n" + "=" * 80 + "\n\n")
            
            print(f"💾 Recommendations exported to: {output_path}\n")
            
        except Exception as e:
            print(f"⚠️  Could not export to file: {e}\n")
    
    def run_analysis(self, export: bool = True):
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
        
        # Print summary
        self.print_conflict_summary(conflicts)
        
        # Generate and print recommendations by node
        node_updates = self.generate_node_recommendations(conflicts)
        self.print_node_recommendations(node_updates)
        
        # Export to file
        if export and node_updates:
            self.export_recommendations_to_file(node_updates)
        
        # Summary
        print("📊 SUMMARY")
        print("=" * 80)
        print(f"Total packages analyzed: {len(self.packages)}")
        print(f"Packages with conflicts: {len(conflicts)}")
        print(f"Custom nodes needing updates: {len(node_updates)}")
        print(f"Reference packages: {len(self.reference_packages)}")
        print()
        
        if node_updates:
            print("Next steps:")
            print("1. Review the recommendations above for each custom node")
            print("2. Copy the recommended package lines into each node's requirements.txt")
            print("3. Run 'pip check' to verify no dependency conflicts")
            print("4. Test ComfyUI to ensure all nodes load successfully")
            print()
            print("💡 TIP: Check 'package_updates.txt' for a saved copy of all recommendations")
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
    parser.add_argument(
        "--no-export",
        action="store_true",
        help="Don't export recommendations to package_updates.txt"
    )
    
    args = parser.parse_args()
    
    analyzer = PackageAnalyzer(args.dir)
    analyzer.run_analysis(export=not args.no_export)


if __name__ == "__main__":
    main()
