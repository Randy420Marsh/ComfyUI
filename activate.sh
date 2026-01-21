#!/usr/bin/env bash

use_cuda13

# 1. Point the build to your 13.1 installation
export UV_LINK_MODE=copy
export BNB_CUDA_VERSION=128
export CUDA_HOME=/usr/local/cuda-13.1
export PATH=$CUDA_HOME/bin:$PATH
export LD_LIBRARY_PATH=$CUDA_HOME/lib64:$LD_LIBRARY_PATH

# 2. Tell PyTorch to ignore the minor version difference (13.1 vs 13.0)
export TORCH_CUDA_ARCH_LIST="7.5"
export FORCE_CUDA=1

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
