#!/bin/bash

BASE_DIR="${CUSTOM_NODES_DIR:-$(dirname "$0")/custom_nodes}"

for dir in "$BASE_DIR"/*; do
    if [ -d "$dir/.git" ]; then
        echo "--------------------------------------------"
        echo "Repository: $dir"
        git -C "$dir" status -s
        echo
    fi
done
