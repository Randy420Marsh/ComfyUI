#!/usr/bin/env bash

# Resolve directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Activating ComfyUI virtual environment..."

# Point directly to the venv path inside the same folder as the script
if [ ! -f "$SCRIPT_DIR/.venv/bin/activate" ]; then
    echo "[ERROR] No venv found at:"
    echo "  $SCRIPT_DIR/.venv/bin/activate"
    exit 1
fi

# Activate into current shell
source "$SCRIPT_DIR/.venv/bin/activate"

echo "Virtual environment activated."
echo "Python: $(python --version)"
echo "Pip:    $(pip --version)"
echo
echo "Use 'deactivate' to exit."
