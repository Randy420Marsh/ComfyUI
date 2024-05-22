#!/bin/bash

echo "Launching..."

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

source ./venv/bin/activate

echo "venv activated"
python --version

# Uncomment and set these variables if needed
# export controlnet_dir="$SD_ROOT_PATH/models/ControlNet"
# export controlnet_annotator_models_path="$SD_ROOT_PATH/models/ControlNet/annotator/models"

python -s main.py --dont-upcast-attention --port 4434 --cpu

# Uncomment if you want to run with different options
# python -s main.py --dont-upcast-attention --port 4434 --highvram --use-pytorch-cross-attention --gpu-only
