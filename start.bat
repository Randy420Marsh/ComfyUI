@echo off

setlocal enabledelayedexpansion

set "PYTHON=python"

echo "Launching..."

cd %CD%

REM ##########################################

set "SD_ROOT_PATH=E://AI//stable_diffusion_models_and_vae"

REM ##########################################

set "USER=%USERNAME%"

echo Current User = %USER%

echo SD models root path = %SD_ROOT_PATH%

set SAFETENSORS_FAST_GPU=1

set PYTORCH_CUDA_ALLOC_CONF=garbage_collection_threshold:0.9,max_split_size_mb:512

call .\venv\scripts\activate.bat

::set python="\\Python-3.10.12\\python.exe"

::set python3="\\Python-3.10.12\\python.exe"

echo "venv activated"
python --version

::#export controlnet_dir="$SD_ROOT_PATH//models//ControlNet"
::#export controlnet_annotator_models_path="$SD_ROOT_PATH//models//ControlNet//annotator//models"

python -s main.py --dont-upcast-attention --port 4434 --highvram --use-pytorch-cross-attention

::--use-pytorch-cross-attention

pause
