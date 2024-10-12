@echo off

echo "This script is updated 2024..."

setlocal enabledelayedexpansion

set python_cmd=python

set "CUSTOM_NODES_DIR=%CD%\custom_nodes"

echo "CUSTOM_NODES_DIR = %CUSTOM_NODES_DIR%"

set "COMFY_UI_DIR=%CD%"

echo "COMFY_UI_DIR = %COMFY_UI_DIR%"

REM Check for NVIDIA GPU
wmic path win32_VideoController get name | findstr /I "NVIDIA" >nul
if %errorlevel%==0 (
    echo NVIDIA GPU detected.
) else (
    echo No NVIDIA GPU detected.
)

REM Prompt user for choice
:choice
set /p user_choice=Do you want to update the GPU or CPU version (G/C)? 
if /I "%user_choice%"=="G" (
    set venv_dir=venv
    set install_cmd=pip install "torch==2.0.1+cu118" "torchvision==0.15.2+cu118" --index-url https://download.pytorch.org/whl/cu118
    echo "Disabling xformers install because of dependency problems..."
    set install_xformers=false
) else if /I "%user_choice%"=="C" (
    set venv_dir=venv-cpu
    set install_cmd=pip install torch torchvision --index-url https://download.pytorch.org/whl/cpu
    set install_xformers=false
) else (
    echo "Invalid choice. Please enter G for GPU version or C for CPU version."
    goto choice
)

%python_cmd% --version

pause

git pull

REM Create and activate virtual environment
if exist %venv_dir%\Scripts\activate (
    call %venv_dir%\Scripts\activate
) else (
    %python_cmd% -m venv %venv_dir%
    call %venv_dir%\Scripts\activate
)

%python_cmd% -m pip install --upgrade pip

cd "COMFY_UI_DIR"

pip uninstall -y torch torchvision xformers torchaudio

REM Install chosen version of torch and torchvision
%install_cmd%

if "%install_xformers%"=="true" (
    pip install xformers
)

cd %CUSTOM_NODES_DIR%

REM set "repos[0]=https://github.com/Randy420Marsh/comfy_controlnet_preprocessors.git"
set "repos[1]=https://github.com/Randy420Marsh/ComfyUI_ADV_CLIP_emb.git"
set "repos[2]=https://github.com/Randy420Marsh/ComfyUI_Comfyroll_CustomNodes.git"
set "repos[3]=https://github.com/Randy420Marsh/comfyui_controlnet_aux.git"
set "repos[4]=https://github.com/Randy420Marsh/ComfyUI_TiledKSampler.git"
set "repos[5]=https://github.com/Randy420Marsh/ComfyUI-Custom-Scripts.git"
set "repos[6]=https://github.com/Randy420Marsh/comfyui-dynamicprompts.git"
set "repos[7]=https://github.com/Randy420Marsh/ComfyUI-Impact-Pack.git"
set "repos[8]=https://github.com/Randy420Marsh/ComfyUI-Manager.git"
set "repos[9]=https://github.com/Randy420Marsh/ComfyUI-QualityOfLifeSuit_Omar92.git"
set "repos[10]=https://github.com/Randy420Marsh/Derfuu_ComfyUI_ModdedNodes.git"
set "repos[11]=https://github.com/Randy420Marsh/efficiency-nodes-comfyui.git"
set "repos[12]=https://github.com/Randy420Marsh/failfast-comfyui-extensions.git"
set "repos[13]=https://github.com/Randy420Marsh/masquerade-nodes-comfyui.git"
set "repos[14]=https://github.com/Randy420Marsh/nui-suite.git"
set "repos[15]=https://github.com/Randy420Marsh/sdxl_prompt_styler.git"
set "repos[16]=https://github.com/Randy420Marsh/SeargeSDXL.git"
set "repos[17]=https://github.com/Randy420Marsh/was-node-suite-comfyui.git"
set "repos[18]=https://github.com/Randy420Marsh/wlsh_nodes.git"
set "repos[19]=https://github.com/Randy420Marsh/ComfyUI-AnimateDiff-Evolved.git"
set "repos[20]=https://github.com/Randy420Marsh/ComfyUI_FizzNodes.git"
set "repos[21]=https://github.com/Randy420Marsh/ComfyUI-VideoHelperSuite.git"
set "repos[22]=https://github.com/Randy420Marsh/ComfyUI-Advanced-ControlNet.git"


for %%i in (1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22) do (
    set "repo_url=!repos[%%i]!"
    for %%j in ("!repo_url!") do (
        set "repo_name=%%~nj"
        
        if exist "!repo_name!%~1" (
            echo "Updating !repo_name!..."
            pushd "!repo_name!%~1"
            git pull
            popd
        ) else (
            echo "Cloning !repo_name!..."
            git clone "%%j" "!repo_name!%~1"
        )
    )
)

REM Obsolete/conflicting node

REM cd %CUSTOM_NODES_DIR%\comfy_controlnet_preprocessors
REM python install-no-re-download.py
REM echo "comfy_controlnet_preprocessors set up..."

REM cd %CUSTOM_NODES_DIR%\comfy_controlnet_preprocessors

REM recursive repos

cd %CUSTOM_NODES_DIR%

set "repos[0]=https://github.com/Randy420Marsh/ComfyUI_UltimateSDUpscale.git --recursive"

for %%i in (0) do (
    set "repo_url=!repos[%%i]!"
    for %%j in ("!repo_url!") do (
        set "repo_name=%%~nj"
        
        if exist "!repo_name!%~1" (
            echo "Updating !repo_name!..."
            pushd "!repo_name!%~1"
            git pull
            popd
        ) else (
            echo "Cloning !repo_name!..."
            git clone "%%j" "!repo_name!%~1"
        )
    )
)

cd %COMFY_UI_DIR%

IF exist ./wildcards (cd wildcards && git reset --hard && git pull && echo "Updated wildcards") ELSE (git clone https://github.com/Randy420Marsh/WC-SDVN.git wildcards && echo "Downloaded/Installed wildcards")


echo "Git clone finished 1/2..."

echo "Now installing custom node dependencies..."
echo
cd %COMFY_UI_DIR%

pip install -r  %CUSTOM_NODES_DIR%\comfyui_controlnet_aux\requirements.txt

pip install -r  %CUSTOM_NODES_DIR%\comfyui-dynamicprompts\requirements.txt

pip install -r  %CUSTOM_NODES_DIR%\efficiency-nodes-comfyui\requirements.txt

pip install -r  %CUSTOM_NODES_DIR%\nui-suite\requirements.txt

pip install -r  %CUSTOM_NODES_DIR%\was-node-suite-comfyui\requirements.txt

pip install -r  %CUSTOM_NODES_DIR%\ComfyUI_FizzNodes\requirements.txt

pip install -r  %CUSTOM_NODES_DIR%\ComfyUI-VideoHelperSuite\requirements.txt

REM pip install -r  %CUSTOM_NODES_DIR%\ComfyUI-Advanced-ControlNet\requirements.txt

echo "Update/install finished 2/2..."

endlocal
pause
