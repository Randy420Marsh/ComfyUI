@echo off

setlocal enabledelayedexpansion

set "PYTHON=python"

echo "Launching..."

cd %CD%

REM ##########################################

set "SD_ROOT_PATH=H://AI//stable_diffusion_models_and_vae"

REM ##########################################

set "USER=%USERNAME%"

echo Current User = %USER%

echo SD models root path = %SD_ROOT_PATH%

set SAFETENSORS_FAST_GPU=1

set PYTORCH_CUDA_ALLOC_CONF=garbage_collection_threshold:0.9,max_split_size_mb:512

call .\venv\scripts\activate.bat

REM set python="C:\\Users\\John\\AppData\\Local\\Programs\\Python\\Python310\\python.exe"

REM set python3="C:\\Users\\John\\AppData\\Local\\Programs\\Python\\Python310\\python.exe"

echo "venv activated"
python --version

set "PATH=%VIRTUAL_ENV%\Scripts;C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Tools\MSVC\14.29.30133\bin\Hostx64\x64;%PATH%"

call "C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Auxiliary\Build\vcvars64.bat"

REM set "ninja.exe=E:\AI\ComfyUI\venv\Scripts\ninja.exe"

REM set "cl.exe=C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Tools\MSVC\14.42.34433\bin\Hostx64\x64\cl.exe"

REM echo %PATH%

::#export controlnet_dir="$SD_ROOT_PATH//models//ControlNet"
::#export controlnet_annotator_models_path="$SD_ROOT_PATH//models//ControlNet//annotator//models"

python -s main.py --dont-upcast-attention --port 4434 --use-pytorch-cross-attention --gpu-only

::--use-pytorch-cross-attention

::python -s main.py --dont-upcast-attention --port 4434 --medvram --use-pytorch-cross-attention --gpu-only

pause
