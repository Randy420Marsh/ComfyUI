@echo off

setlocal enabledelayedexpansion

set "CUSTOM_NODES_DIR=%CD%\custom_nodes"

echo CUSTOM_NODES_DIR = %CUSTOM_NODES_DIR%

set "COMFY_UI_DIR=%CD%"

echo COMFY_UI_DIR = %COMFY_UI_DIR%

set python="C:\\Users\\John\\AppData\\Local\\Programs\\Python\\Python310\\python.exe"

set python3="C:\\Users\\John\\AppData\\Local\\Programs\\Python\\Python310\\python.exe"

echo "venv activated"
python --version

set "PATH=%VIRTUAL_ENV%\Scripts;C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Tools\MSVC\14.29.30133\bin\Hostx64\x64;%PATH%"

call "C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Auxiliary\Build\vcvars64.bat"

IF exist ./venv (call .\venv\scripts\activate.bat) ELSE ("python" -m venv venv && call .\venv\scripts\activate.bat)

python --version

python.exe -m pip install --upgrade pip

pip uninstall -y torch torchvision xformers

pip install "torch==2.1.2+cu121" "torchvision==0.16.2+cu121" "torchaudio==2.1.2+cu121" "xformers==0.0.23.post1" --index-url https://download.pytorch.org/whl/cu121

git pull

pip install -r requirements.txt

cd custom_nodes

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
set "repos[23]=https://github.com/Randy420Marsh/human-parser-comfyui-node.git"
set "repos[24]=https://github.com/Randy420Marsh/ComfyUI-Allor.git"
set "repos[25]=https://github.com/Randy420Marsh/ControlNet-LLLite-ComfyUI.git"
set "repos[26]=https://github.com/Randy420Marsh/ComfyUI-WD14-Tagger.git"
set "repos[27]=https://github.com/Randy420Marsh/ComfyUI_essentials.git"


for %%i in (1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27) do (
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

REM recursive repos

cd custom_nodes

set "repos[0]=https://github.com/Randy420Marsh/ComfyUI_UltimateSDUpscale.git --recursive"

for %%i in (0) do (
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

cd %COMFY_UI_DIR%

IF exist ./wildcards (cd wildcards && git reset --hard && git pull && echo "Updated wildcards") ELSE (git clone https://github.com/Randy420Marsh/WC-SDVN.git wildcards && echo "Downloaded/Installed wildcards")


echo "Git clone finished 1/2..."

REM Obsolete/conflicting node

REM cd %CUSTOM_NODES_DIR%\comfy_controlnet_preprocessors
REM python install-no-re-download.py
REM echo "comfy_controlnet_preprocessors set up..."

REM cd %CUSTOM_NODES_DIR%\comfy_controlnet_preprocessors

cd %COMFY_UI_DIR%

pip install -r %CUSTOM_NODES_DIR%\comfyui_controlnet_aux\requirements.txt

pip install -r %CUSTOM_NODES_DIR%\comfyui-dynamicprompts\requirements.txt

pip install -r %CUSTOM_NODES_DIR%\efficiency-nodes-comfyui\requirements.txt

pip install -r %CUSTOM_NODES_DIR%\ComfyUI-Impact-Pack\requirements.txt

pip install -r %CUSTOM_NODES_DIR%\nui-suite\requirements.txt

pip install -r %CUSTOM_NODES_DIR%\was-node-suite-comfyui\requirements.txt

pip install -r %CUSTOM_NODES_DIR%\ComfyUI_FizzNodes\requirements.txt

pip install -r %CUSTOM_NODES_DIR%\ComfyUI-VideoHelperSuite\requirements.txt

pip install -r %CUSTOM_NODES_DIR%\human-parser-comfyui-node\requirements.txt

pip install -r %CUSTOM_NODES_DIR%\ComfyUI-Allor\requirements.txt

pip install -r %CUSTOM_NODES_DIR%\ComfyUI-WD14-Tagger\requirements.txt

pip install -r %CUSTOM_NODES_DIR%\ComfyUI_essentials\requirements.txt

REM pip install -r  %CUSTOM_NODES_DIR%\ComfyUI-Advanced-ControlNet\requirements.txt

echo Fixing dependencies...

pip install -r requirements.txt

pip install "scikit-learn-intelex" "numpy==1.26.4" "thinc" "daal" "daal4py" "ultralytics" "setuptools==72.1.0" torchsde aiohttp spacy spandrel kornia av 

REM "onnx==1.17.0"

REM This should fix broken/corrupted install...
REM pip install --force-reinstall "scikit-learn-intelex" "numpy==1.26.4" "thinc<8.4.0,>=8.3.0" "daal==2024.7.0" "daal4py==2024.7.0" "ultralytics"

pip install onnxruntime-gpu --index-url https://aiinfra.pkgs.visualstudio.com/PublicPackages/_packaging/onnxruntime-cuda-11/pypi/simple/

REM onnx instructions: https://onnxruntime.ai/docs/install/

echo "Copy python libs to venv"

mkdir "%COMFY_UI_DIR%\venv\Scripts\libs\"

copy "C:\Program Files\Python310\libs\*" "%COMFY_UI_DIR%\venv\Scripts\libs\"

echo Update/install finished 2/2...

endlocal
pause
