#!/usr/bin/env python3
import os
from pathlib import Path

# Your custom_nodes path (change only if needed)
CUSTOM_NODES_PATH = Path("/media/john/35ff53f0-74df-4018-90b0-4ee8a466e97e/AI/ComfyUI/custom_nodes")

# Deprecated legacy paths that trigger the warnings
DEPRECATED_PATTERNS = [
    "widgetInputs.js",
    "ui.js",
    "groupNode.js",
    "clipspace.js",
    "buttonGroup.js",
    "button.js",
    "/extensions/core/widgetInputs.js",
    "/scripts/ui.js",
    "/extensions/core/groupNode.js",
    "/extensions/core/clipspace.js",
    "/scripts/ui/components/buttonGroup.js",
    "/scripts/ui/components/button.js",
]

def find_legacy_imports():
    print("🔍 Scanning custom nodes for legacy API imports...\n")
    found_any = False

    for node_dir in CUSTOM_NODES_PATH.iterdir():
        if not node_dir.is_dir():
            continue

        node_name = node_dir.name
        legacy_files = []

        # Scan all .js files recursively
        for js_file in node_dir.rglob("*.js"):
            try:
                content = js_file.read_text(encoding="utf-8", errors="ignore")
                for pattern in DEPRECATED_PATTERNS:
                    if pattern in content:
                        # Show relative path and the matching line
                        lines = [line for line in content.splitlines() if pattern in line]
                        for line in lines[:3]:  # show up to 3 matching lines
                            legacy_files.append(f"  → {js_file.relative_to(CUSTOM_NODES_PATH)} : {line.strip()}")
                        break  # no need to check other patterns for this file
            except Exception:
                pass  # skip unreadable files

        if legacy_files:
            found_any = True
            print(f"🚨 LEGACY FOUND in: {node_name}")
            for entry in legacy_files:
                print(entry)
            print()

    if not found_any:
        print("✅ No legacy API imports found in any custom node!")
    else:
        print("💡 These are the exact nodes (and JS files) you need to update or disable.")
        print("   Check their GitHub for updates or open an issue with the author.")

if __name__ == "__main__":
    find_legacy_imports()
