#!/usr/bin/env bash

# Remove all external linker pollution
unset LD_LIBRARY_PATH

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/.venv/bin/activate"

echo "Activated clean CUDA environment."

echo "Virtual environment activated."
echo "Python: $(python --version)"
echo "Pip:    $(pip --version)"
