@echo off
setlocal EnableDelayedExpansion

REM ------------------------------------------
REM  Equivalent of the Linux launch.sh script
REM  Adapted for Windows
REM ------------------------------------------

REM Disable mmap (Windows NTFS does not support it)
REM set COMFYUI_DISABLE_MMAP=0

REM DreamBooth flags
REM set DREAMBOOTH_SKIP_INSTALL=True

REM Offline modes
REM set HF_DATASETS_OFFLINE=1
REM TRANSFORMRRS_OFFLINE=1

REM Display threads (Windows has no `nproc`)
REM echo Threads (informational only): %NUMBER_OF_PROCESSORS%

REM Custom CUDA path if needed
REM Modify if you are using CUDA toolkit manually installed
REM set "PATH=C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v13.0\bin;%PATH%"

REM SAFETENSORS acceleration
REM set SAFETENSORS_FAST_GPU=1

REM Path where this script is executed
set COMFYUI_PATH=%cd%
set USER=%USERNAME%

echo Current User: %USER%
echo ComfyUI Path: %COMFYUI_PATH%

REM ------------------------------------------
REM Activate Python virtual environment
REM ------------------------------------------
IF EXIST .\venv\Scripts\activate.bat (
    call .\venv\Scripts\activate.bat
    echo venv activated
) ELSE (
    echo ERROR: .\venv not found. Please create it first.
    pause
    exit /b 1
)

REM Python executable
set python=python
set python3=python

%python3% --version

echo Launching ComfyUI...
echo To disable comfy registry update set network_mode = private in ComfyUI\user\default\ComfyUI-Manager\config.ini

REM ------------------------------------------
REM Launch ComfyUI
REM ------------------------------------------
%python3% -s main.py --dont-upcast-attention --port 4434 --normalvram --use-pytorch-cross-attention --disable-mmap --listen 127.0.0.1

REM Alternate launch:
REM %python3% -s main.py --dont-upcast-attention --port 4434 --use-pytorch-cross-attention

endlocal
