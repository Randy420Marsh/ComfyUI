@echo off
echo This script is updated 2024...

git pull

set python_cmd=python3.10

set CUSTOM_NODES_DIR=%cd%\custom_nodes
echo CUSTOM_NODES_DIR = %CUSTOM_NODES_DIR%

set COMFY_UI_DIR=%cd%
echo COMFY_UI_DIR = %COMFY_UI_DIR%

REM Check for NVIDIA GPU
wmic path win32_VideoController get name | findstr /I "NVIDIA"
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
    set install_cmd=pip install torch torchvision --index-url https://download.pytorch.org/whl/cu118
    set install_xformers=true
) else if /I "%user_choice%"=="C" (
    set venv_dir=venv-cpu
    set install_cmd=pip install torch torchvision --index-url https://download.pytorch.org/whl/cpu
    set install_xformers=false
) else (
    echo Invalid choice. Please enter G for GPU version or C for CPU version.
    goto choice
)

%python_cmd% --version

pause

REM Create and activate virtual environment
if exist %venv_dir%\Scripts\activate (
    call %venv_dir%\Scripts\activate
) else (
    %python_cmd% -m venv %venv_dir%
    call %venv_dir%\Scripts\activate
)

%python_cmd% -m pip install --upgrade pip

cd %COMFY_UI_DIR%

pip uninstall -y torch torchvision xformers

REM Install chosen version of torch and torchvision
%install_cmd%

pip install -r requirements.txt

if "%install_xformers%"=="true" (
    pip install xformers
)

cd %CUSTOM_NODES_DIR%

set repos=(
    https://github.com/Randy420Marsh/ComfyUI_ADV_CLIP_emb.git
    https://github.com/Randy420Marsh/ComfyUI_Comfyroll_CustomNodes.git
    https://github.com/Randy420Marsh/comfyui_controlnet_aux.git
    https://github.com/Randy420Marsh/ComfyUI_TiledKSampler.git
    https://github.com/Randy420Marsh/ComfyUI-Custom-Scripts.git
    https://github.com/Randy420Marsh/comfyui-dynamicprompts.git
    https://github.com/Randy420Marsh/ComfyUI-Impact-Pack.git
    https://github.com/Randy420Marsh/ComfyUI-Manager.git
    https://github.com/Randy420Marsh/ComfyUI-QualityOfLifeSuit_Omar92.git
    https://github.com/Randy420Marsh/Derfuu_ComfyUI_ModdedNodes.git
    https://github.com/Randy420Marsh/efficiency-nodes-comfyui.git
    https://github.com/Randy420Marsh/failfast-comfyui-extensions.git
    https://github.com/Randy420Marsh/masquerade-nodes-comfyui.git
    https://github.com/Randy420Marsh/nui-suite.git
    https://github.com/Randy420Marsh/sdxl_prompt_styler.git
    https://github.com/Randy420Marsh/SeargeSDXL.git
    https://github.com/Randy420Marsh/was-node-suite-comfyui.git
    https://github.com/Randy420Marsh/wlsh_nodes.git
)

for %%i in %repos% do (
    set repo_url=%%i
    set repo_name=%repo_url:~%repo_url:rpath%\%.git
    if exist %repo_name% (
        echo Updating %repo_name%...
        pushd %repo_name%
        git pull
        popd
    ) else (
        echo Cloning %repo_name%...
        git clone %repo_url% %repo_name%
    )
)

REM Recursive repo
set repo_url=https://github.com/Randy420Marsh/ComfyUI_UltimateSDUpscale.git --recursive
set repo_name=%repo_url:~%repo_url:rpath%\%.git

if exist %repo_name% (
    echo Updating %repo_name%...
    pushd %repo_name%
    git pull
    popd
) else (
    echo Cloning %repo_name%...
    git clone %repo_url% %repo_name%
)

cd %COMFY_UI_DIR%

if exist .\wildcards (
    cd wildcards
    git reset --hard
    git pull
    echo Updated wildcards
) else (
    git clone https://github.com/Randy420Marsh/WC-SDVN.git wildcards
    echo Downloaded/Installed wildcards
)

echo Git clone finished 1/2...

cd %COMFY_UI_DIR%

pip install -r %CUSTOM_NODES_DIR%\comfyui_controlnet_aux\requirements.txt
pip install -r %CUSTOM_NODES_DIR%\comfyui-dynamicprompts\requirements.txt
pip install -r %CUSTOM_NODES_DIR%\efficiency-nodes-comfyui\requirements.txt
pip install -r %CUSTOM_NODES_DIR%\nui-suite\requirements.txt
pip install -r %CUSTOM_NODES_DIR%\was-node-suite-comfyui\requirements.txt

echo Update/install finished 2/2...

