#!/usr/bin/env bash

# Remove all external linker pollution
unset LD_LIBRARY_PATH

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

export BNB_CUDA_VERSION=130
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/cuda-13.0/lib64

export UV_LINK_MODE=copy

source "$SCRIPT_DIR/.venv/bin/activate"

echo "Activated clean CUDA environment."

echo "Virtual environment activated."
echo "Python: $(python --version)"
echo "Pip:    $(pip --version)"
