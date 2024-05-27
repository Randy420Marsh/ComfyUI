#!/bin/bash

echo "Launching..."

# Determine the maximum number of available CPU threads
MAX_THREADS=$(nproc)

# Set the environment variables
export OMP_NUM_THREADS=$MAX_THREADS
export MKL_NUM_THREADS=$MAX_THREADS

echo "Using $MAX_THREADS threads for OMP and MKL"

export LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libjemalloc.so:$LD_PRELOAD
export MALLOC_CONF="oversize_threshold:1,background_thread:true,metadata_thp:auto,dirty_decay_ms: 60000,muzzy_decay_ms:60000"
export LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libiomp5.so:$LD_PRELOAD

python_cmd="python3.10"

# Check if the script is run as root
if [ "$USER" == "root" ]; then
    echo "Warning: This script cannot be run as root."
    read -p "Press any key to exit..."
    exit 1
fi

cd "$(pwd)"

# ##########################################
SD_ROOT_PATH="$USER//AI//ComfyUI-dev//models"
# ##########################################

USER=$(whoami)
USER_HOME="//home//$USER"

echo "Current User = $USER"
echo "User Home Directory = $USER_HOME"
echo "SD models root path = $SD_ROOT_PATH"

#export SAFETENSORS_FAST_GPU=1
#export PYTORCH_CUDA_ALLOC_CONF="garbage_collection_threshold:0.9,max_split_size_mb:512"

source ./venv-cpu/bin/activate

echo "venv-cpu activated"
$python_cmd --version

# Uncomment and set these variables if needed
# export controlnet_dir="$SD_ROOT_PATH/models/ControlNet"
# export controlnet_annotator_models_path="$SD_ROOT_PATH/models/ControlNet/annotator/models"

$python_cmd -s main.py --dont-upcast-attention --port 4434 --cpu --preview-method auto

