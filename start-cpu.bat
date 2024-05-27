@echo off

setlocal enabledelayedexpansion

set "PYTHON=python"

echo "Launching..."

cd %CD%

REM ##########################################

set "SD_ROOT_PATH=C://AI//AUTOMATIC1111-dev//models"

REM ##########################################

set "USER=%USERNAME%"

echo Current User = %USER%

echo SD models root path = %SD_ROOT_PATH%

set SAFETENSORS_FAST_GPU=1

REM set PYTORCH_CUDA_ALLOC_CONF=garbage_collection_threshold:0.9,max_split_size_mb:512

call .\venv-cpu\scripts\activate.bat

echo "venv-cpu activated"
%PYTHON% --version

::#export controlnet_dir="$SD_ROOT_PATH//models//ControlNet"
::#export controlnet_annotator_models_path="$SD_ROOT_PATH//models//ControlNet//annotator//models"

%PYTHON% -s main.py --dont-upcast-attention --port 4434 --cpu --preview-method auto

pause
