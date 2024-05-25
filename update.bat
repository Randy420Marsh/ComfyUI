@echo off

echo This script is updated 2024...

set "python_cmd=python"

set "CUSTOM_NODES_DIR=%CD%\custom_nodes"
echo CUSTOM_NODES_DIR = %CUSTOM_NODES_DIR%

set "COMFY_UI_DIR=%CD%"
echo COMFY_UI_DIR = %COMFY_UI_DIR%

:: Prompt user for choice
:choice
set /p "user_choice=Do you want to update the GPU or CPU version (G/C)? "

if /i "%user_choice%"=="G" (
    set "venv_dir=venv"
    set "install_cmd=pip install torch torchvision --index-url https://download.pytorch.org/whl/cu118"
    set "install_xformers=true"
) else if /i "%user_choice%"=="C" (
    set "venv_dir=venv-cpu"
    set "install_cmd=pip install torch torchvision --index-url https://download.pytorch.org/whl/cpu"
    set "install_xformers=false"
) else (
    echo Invalid choice. Please enter G for GPU version or C for CPU version.
    goto choice
)

:: Create and activate virtual environment
if exist "%venv_dir%" (
    call "%venv_dir%\Scripts\activate"
) else (
    %python_cmd% -m venv %venv_dir%
    call "%venv_dir%\Scripts\activate"
)

%python_cmd% --version

pause

pip uninstall -y torch torchvision xformers

:: Install chosen version of torch and torchvision
%install_cmd%

if "%install_xformers%"=="true" (
    pip install xformers
)

%python_cmd% -m pip install --upgrade pip

git pull

pip install -r requirements.txt

cd custom_nodes

set repos[0]=https://github.com/Randy420Marsh/ComfyUI_ADV_CLIP_emb.git
set repos[1]=https://github.com/Randy420Marsh/ComfyUI_Comfyroll_CustomNodes.git
set repos[2]=https://github.com/Randy420Marsh/comfyui_controlnet_aux.git
set repos[3]=https://github.com/Randy420Marsh/ComfyUI_TiledKSampler.git
set repos[4]=https://github.com/Randy420Marsh/ComfyUI-Custom-Scripts.git
set repos[5]=https://github.com/Randy420Marsh/comfyui-dynamicprompts.git
set repos[6]=https://github.com/Randy420Marsh/ComfyUI-Impact-Pack.git
set repos[7]=https://github.com/Randy420Marsh/ComfyUI-Manager.git
set repos[8]=https://github.com/Randy420Marsh/ComfyUI-QualityOfLifeSuit_Omar92.git
set repos[9]=https://github.com/Randy420Marsh/Derfuu_ComfyUI_ModdedNodes.git
set repos[10]=https://github.com/Randy420Marsh/efficiency-nodes-comfyui.git
set repos[11]=https://github.com/Randy420Marsh/failfast-comfyui-extensions.git
set repos[12]=https://github.com/Randy420Marsh/masquerade-nodes-comfyui.git
set repos[13]=https://github.com/Randy420Marsh/nui-suite.git
set repos[14]=https://github.com/Randy420Marsh/sdxl_prompt_styler.git
set repos[15]=https://github.com/Randy420Marsh/SeargeSDXL.git
set repos[16]=https://github.com/Randy420Marsh/was-node-suite-comfyui.git
set repos[17]=https://github.com/Randy420Marsh/wlsh_nodes.git

for /L %%i in (0,1,17) do (
    set "repo_url=!repos[%%i]!"
    for %%j in ("!repo_url!") do (
        set "repo_name=%%~nj"
        
        if exist "!repo_name!%~1" (
            echo Updating !repo_name!...
            pushd "!repo_name!%~1"
            git pull
            popd
        ) else (
            echo Cloning !repo_name!...
            git clone "%%j" "!repo_name!%~1"
        )
    )
)

:: Recursive repos
cd custom_nodes

set "repo_url=https://github.com/Randy420Marsh/ComfyUI_UltimateSDUpscale.git --recursive"
for %%j in ("!repo_url!") do (
    set "repo_name=%%~nj"

    if exist "!repo_name!%~1" (
        echo Updating !repo_name!...
        pushd "!repo_name!%~1"
        git pull
        popd
    ) else (
        echo Cloning !repo_name!...
        git clone "%%j" "!repo_name!%~1"
    )
)

cd "%COMFY_UI_DIR%"

if exist "./wildcards" (
    cd wildcards
    git reset --hard
    git pull
    echo Updated wildcards
) else (
    git clone https://github.com/Randy420Marsh/WC-SDVN.git wildcards
    echo Downloaded/Installed wildcards
)

echo Git clone finished 1/2...

cd "%COMFY_UI_DIR%"

pip install -r "%CUSTOM_NODES_DIR%\comfyui_controlnet_aux\requirements.txt"
pip install -r "%CUSTOM_NODES_DIR%\comfyui-dynamicprompts\requirements.txt"
pip install -r "%CUSTOM_NODES_DIR%\efficiency-nodes-comfyui\requirements.txt"
pip install -r "%CUSTOM_NODES_DIR%\nui-suite\requirements.txt"
pip install -r "%CUSTOM_NODES_DIR%\was-node-suite-comfyui\requirements.txt"

echo Update/install finished 2/2...
