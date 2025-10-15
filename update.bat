@echo off
setlocal enabledelayedexpansion

set "CUSTOM_NODES_DIR=%cd%\custom_nodes"
echo CUSTOM_NODES_DIR = %CUSTOM_NODES_DIR%

set "COMFY_UI_DIR=%cd%"
echo COMFY_UI_DIR = %COMFY_UI_DIR%

if exist "venv" (
    call venv\Scripts\activate.bat
) else (
    python -m venv venv
    call venv\Scripts\activate.bat
)

rem where python
rem if %errorlevel% neq 0 (
rem     echo Python not found. Please install Python and try again.
rem     pause
rem     exit /b 1
rem )

set "python=C:\Program Files\Python312\python.exe"

echo.
echo Press Enter to continue...
pause > nul
echo.

python -m pip install --upgrade pip

git pull

pip install --upgrade -r requirements.txt

cd %CUSTOM_NODES_DIR%

rem Define the repositories in an array-like structure
set "repos[0]=https://github.com/Randy420Marsh/ComfyUI_ADV_CLIP_emb.git"
set "repos[1]=https://github.com/Randy420Marsh/ComfyUI_Comfyroll_CustomNodes.git"
set "repos[2]=https://github.com/Randy420Marsh/comfyui_controlnet_aux.git"
set "repos[3]=https://github.com/Randy420Marsh/ComfyUI_TiledKSampler.git"
set "repos[4]=https://github.com/Randy420Marsh/ComfyUI-Custom-Scripts.git"
set "repos[5]=https://github.com/Randy420Marsh/comfyui-dynamicprompts.git"
set "repos[6]=https://github.com/Randy420Marsh/ComfyUI-Impact-Pack.git"
set "repos[7]=https://github.com/Randy420Marsh/ComfyUI-Manager.git"
set "repos[8]=https://github.com/Randy420Marsh/ComfyUI-QualityOfLifeSuit_Omar92.git"
set "repos[9]=https://github.com/Randy420Marsh/Derfuu_ComfyUI_ModdedNodes.git"
set "repos[10]=https://github.com/Randy420Marsh/efficiency-nodes-comfyui.git"
set "repos[11]=https://github.com/Randy420Marsh/failfast-comfyui-extensions.git"
set "repos[12]=https://github.com/Randy420Marsh/masquerade-nodes-comfyui.git"
set "repos[13]=https://github.com/Randy420Marsh/nui-suite.git"
set "repos[14]=https://github.com/Randy420Marsh/sdxl_prompt_styler.git"
set "repos[15]=https://github.com/Randy420Marsh/SeargeSDXL.git"
set "repos[16]=https://github.com/Randy420Marsh/was-node-suite-comfyui.git"
set "repos[17]=https://github.com/Randy420Marsh/wlsh_nodes.git"
set "repos[18]=https://github.com/Randy420Marsh/ComfyUI-AnimateDiff-Evolved.git"
set "repos[19]=https://github.com/Randy420Marsh/ComfyUI_FizzNodes.git"
set "repos[20]=https://github.com/Randy420Marsh/ComfyUI-VideoHelperSuite.git"
set "repos[21]=https://github.com/Randy420Marsh/ComfyUI-Advanced-ControlNet.git"
set "repos[22]=https://github.com/Randy420Marsh/human-parser-comfyui-node-in-pure-python.git"
set "repos[23]=https://github.com/Randy420Marsh/ComfyUI-Allor.git"
set "repos[24]=https://github.com/Randy420Marsh/ControlNet-LLLite-ComfyUI.git"
set "repos[25]=https://github.com/Randy420Marsh/ComfyUI-WD14-Tagger.git"
set "repos[26]=https://github.com/Randy420Marsh/ComfyUI_essentials.git"
set "repos[27]=https://github.com/Randy420Marsh/comfy_mtb.git"
set "repos[28]=https://github.com/Randy420Marsh/ComfyUI-Yolo-World-EfficientSAM.git"
set "repos[29]=https://github.com/Randy420Marsh/ComfyUI-CLIPSeg.git"
set "repos[30]=https://github.com/Randy420Marsh/ComfyUI-KJNodes.git"
set "repos[31]=https://github.com/Randy420Marsh/ComfyUI-Impact-Subpack.git"
set "repos[32]=https://github.com/Randy420Marsh/ComfyUI_TensorRT.git"
set "repos[33]=https://github.com/Randy420Marsh/ComfyUI-ModelQuantizer.git"
set "repos[34]=https://github.com/Randy420Marsh/ComfyUI-GGUF.git"

for /L %%i in (0,1,34) do (
    call :process_repo !repos[%%i]!
)

goto :end_repos

:process_repo
    set "repo_url=%1"
    for %%j in ("%repo_url%") do set "repo_name=%%~nj"
    
    if exist "!repo_name!" (
        echo Updating !repo_name!...
        cd "!repo_name!"
        git pull
        cd ..
    ) else (
        echo Cloning !repo_name!...
        git clone "!repo_url!" "!repo_name!"
    )
    goto :eof

:end_repos

rem Recursive repos
set "repo_url=https://github.com/Randy420Marsh/ComfyUI_UltimateSDUpscale.git"
set "repo_name=ComfyUI_UltimateSDUpscale"
rem Note: The original script had "--recursive" as part of the URL, which is incorrect. It should be a separate argument.

if exist "!repo_name!" (
    echo Updating !repo_name!...
    cd "!repo_name!"
    git pull
    cd ..
) else (
    echo Cloning !repo_name!...
    git clone %repo_url% --recursive "!repo_name!"
)

cd %COMFY_UI_DIR%

if exist "wildcards" (
    cd wildcards
    git reset --hard
    git pull
    echo Updated wildcards
    cd ..
) else (
    git clone https://github.com/Randy420Marsh/WC-SDVN.git wildcards
    echo Downloaded/Installed wildcards
)

echo Git clone finished 1/2...

cd %COMFY_UI_DIR%

pip install -r "%CUSTOM_NODES_DIR%/comfyui_controlnet_aux/requirements.txt"
pip install -r "%CUSTOM_NODES_DIR%/comfyui-dynamicprompts/requirements.txt"
pip install -r "%CUSTOM_NODES_DIR%/efficiency-nodes-comfyui/requirements.txt"
pip install -r "%CUSTOM_NODES_DIR%/ComfyUI-Impact-Pack/requirements.txt"
pip install -r "%CUSTOM_NODES_DIR%/nui-suite/requirements.txt"
pip install -r "%CUSTOM_NODES_DIR%/was-node-suite-comfyui/requirements.txt"
pip install -r "%CUSTOM_NODES_DIR%/ComfyUI_FizzNodes/requirements.txt"
pip install -r "%CUSTOM_NODES_DIR%/ComfyUI-VideoHelperSuite/requirements.txt"
pip install -r "%CUSTOM_NODES_DIR%/human-parser-comfyui-node-in-pure-python/requirements.txt"
pip install -r "%CUSTOM_NODES_DIR%/ComfyUI-Allor/requirements.txt"
pip install -r "%CUSTOM_NODES_DIR%/ComfyUI-WD14-Tagger/requirements.txt"
pip install -r "%CUSTOM_NODES_DIR%/ComfyUI_essentials/requirements.txt"
pip install -r "%CUSTOM_NODES_DIR%/comfy_mtb/requirements.txt"
pip install -r "%CUSTOM_NODES_DIR%/ComfyUI-Yolo-World-EfficientSAM/requirements.txt"
pip install -r "%CUSTOM_NODES_DIR%/ComfyUI-CLIPSeg/requirements.txt"
pip install -r "%CUSTOM_NODES_DIR%/ComfyUI-KJNodes/requirements.txt"
pip install -r "%CUSTOM_NODES_DIR%/ComfyUI_TensorRT/requirements.txt"
pip install -r "%CUSTOM_NODES_DIR%/ComfyUI-ModelQuantizer/requirements.txt"
pip install -r "%CUSTOM_NODES_DIR%/ComfyUI-GGUF/requirements.txt"

cd "%CUSTOM_NODES_DIR%/ComfyUI-Impact-Subpack"
python install.py
pip install -r requirements.txt
cd %COMFY_UI_DIR%

pip uninstall onnxruntime-gpu onnxruntime -y

pip uninstall -y torch torchvision torchaudio xformers

REM pip install --upgrade "inference[sam]" "inference[grounding-dino]" "inference[transformers]" "mediapipe" "Pillow<10,>=9.0.0" "scikit-learn-intelex" "numpy==1.26.4" "thinc" "daal" "daal4py" "ultralytics" "setuptools" "aiortc" "av" "albumentations==1.4.4" "pydantic>=2.9.2" "sam>=2" torchsde aiohttp spacy spandrel kornia av pynvml

pip install --upgrade "torch==2.7.1+cu128" "torchaudio==2.7.1+cu128" "torchvision==0.22.1+cu128" --index-url https://download.pytorch.org/whl/cu128

REM pip install onnxruntime-gpu inference-gpu opencv-python-headless "numpy<2,>=1"

REM pip install supervision==0.22.0 inference inference-gpu tokenizers

pip install --upgrade -r win-requirements.txt

echo Update/install finished 2/2...

endlocal
pause