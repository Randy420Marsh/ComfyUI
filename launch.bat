@echo off
setlocal

rem Set the environment variables
rem Note: These are for Linux and may not have a direct equivalent or be necessary on Windows.
rem We are setting them as a best-effort conversion.

rem Disable mmap because it is not supported on ntfs partitions.
rem This is defined in ./comfy/utils.py at line 54.

rem set COMFYUI_DISABLE_MMAP=0

rem Dreambooth
rem set DREAMBOOTH_SKIP_INSTALL=True

rem Offline mode for HuggingFace
rem set HF_DATASETS_OFFLINE=1
rem set TRANSFORMERS_OFFLINE=1

rem LD_PRELOAD variables are Linux-specific and removed.
rem The libraries libjemalloc.so and libiomp5.so are for Linux memory management and OpenMP.

rem Set CUDA library path - This is for Windows, the Linux path is removed.
rem You may need to adjust this path based on your CUDA installation.
rem set PATH=%PATH%;C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v12.8\bin
rem set PATH=%PATH%;C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v12.8\lib\x64

rem Custom SD models root path
rem set SD_ROOT_PATH="F:\AI\stable_diffusion_models_and_vae"
rem set COMFYUI_MODEL_PATH=%SD_ROOT_PATH%

rem echo SD models root path:
rem echo %SD_ROOT_PATH%

rem SAFETENSORS_FAST_GPU
set SAFETENSORS_FAST_GPU=1

set TF_ENABLE_ONEDNN_OPTS=0

rem PyTorch memory allocation
set PYTORCH_CUDA_ALLOC_CONF=garbage_collection_threshold:0.9,max_split_size_mb:512

rem Activate the Python virtual environment
if exist "venv" (
    call "venv\Scripts\activate.bat"
) else (
    echo Virtual environment not found. Please run the install script first.
    pause
    exit /b 1
)

echo venv activated

rem Set Python executable variable (optional, "python" should work)
set python="python"
set python3="python"

echo Launching...

%python% --version

echo To disable comfy registry update set network_mode = private in ComfyUI/user/default/ComfyUI-Manager/config.ini

rem Start ComfyUI
rem The -s parameter is for Linux, replaced with -s in the Python call for consistency if needed.
%python% main.py --port 4434 --use-pytorch-cross-attention --normalvram

rem %python% main.py --dont-upcast-attention --port 4434 --normalvram --use-pytorch-cross-attention

rem %python% main.py --dont-upcast-attention --port 4434 --normalvram --use-pytorch-cross-attention --disable-mmap

endlocal
pause