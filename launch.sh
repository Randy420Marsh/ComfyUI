#!/bin/bash

# Determine the maximum number of available CPU threads
#MAX_THREADS=$(nproc)

# Set the environment variables

#Disable mmap because it is not supported on ntfs partitions, enable or uncomment if using ext filesystem for better performance
#this is defined in ./comfy/utils.py at line 54.

export COMFYUI_DISABLE_MMAP=0

#export omp_set_max_active_levels=$MAX_THREADS
#export MKL_NUM_THREADS=$MAX_THREADS

export DREAMBOOTH_SKIP_INSTALL=True

export HF_DATASETS_OFFLINE=1
export TRANSFORMRRS_OFFLINE=1

echo "Using $MAX_THREADS threads for OMP and MKL"

#export LD_PRELOAD=/usr/local/lib/libjemalloc.so:$LD_PRELOAD
#export MALLOC_CONF="oversize_threshold:1,background_thread:true,metadata_thp:auto,dirty_decay_ms: 60000,muzzy_decay_ms:60000"
#export LD_PRELOAD=/lib/x86_64-linux-gnu/libiomp5.so:$LD_PRELOAD

#export model_args.use_multiprocessing=False

export LD_LIBRARY_PATH=/usr/local/cuda-13.1/lib64

#Uncomment as needed...

#Custom SD models root drive

##########################################

#CUSTOM_ROOT_DRIVE="d8b779b2-12b5-4cd9-82e0-a5dcfe75608a"

AUTOMATIC1111_WEBUI="AUTOMATIC1111"

##########################################

# python3 executable
python_cmd="./.venv/bin/python"

##########################################

cd $PWD

USER="$USER"

export USER=$USER

echo "Current User: $USER"

#Custom AUTOMATIC1111 webui root path

COMFYUI_PATH=$PWD

export COMFYUI_PATH=$PWD

#SD_ROOT_PATH="/media/john/20TB/AI/stable_diffusion_models_and_vae"

#export SD_ROOT_PATH="/media/john/20TB/AI/stable_diffusion_models_and_vae"

#COMFYUI_MODEL_PATH="/media/john/20TB/AI/stable_diffusion_models_and_vae"

#export COMFYUI_MODEL_PATH="/media/john/20TB/AI/stable_diffusion_models_and_vae"



#echo "Current active SD root path:"

#echo $CUSTOM_ROOT_DRIVE

#echo "SD models root path:"

#echo $SD_ROOT_PATH

export SAFETENSORS_FAST_GPU=1

#export PYTORCH_CUDA_ALLOC_CONF=garbage_collection_threshold:0.9,max_split_size_mb:512

source ./.venv/bin/activate

echo "venv activated"

export SAFETENSORS_FAST_GPU=1

python="python3.12"

python3="python3.12"

echo "Launching..."

python3 --version

echo "To disable comfy registry update set network_mode = private in ComfyUI/user/default/ComfyUI-Manager/config.ini"

#export controlnet_dir="$SD_ROOT_PATH/models/ControlNet"
#export controlnet_annotator_models_path="$SD_ROOT_PATH/models/ControlNet/annotator/models"

python3 -s main.py --dont-upcast-attention --port 4434 --normalvram --use-pytorch-cross-attention --listen 127.0.0.1

#python3 -s main.py --dont-upcast-attention --port 4434 --use-pytorch-cross-attention
