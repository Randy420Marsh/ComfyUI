#!/bin/bash

CUSTOM_NODES_DIR="$(pwd)/custom_nodes"
echo "CUSTOM_NODES_DIR = $CUSTOM_NODES_DIR"

COMFY_UI_DIR="$(pwd)"
echo "COMFY_UI_DIR = $COMFY_UI_DIR"

if [ -d "./venv" ]; then
    source ./venv/bin/activate
else
    python3.10 -m venv venv
    source ./venv/bin/activate
fi

python --version

read -p "Press Enter to continue..."

pip uninstall -y torch torchvision xformers

pip install "torch==2.7.0+cu128" "torchvision==0.22.0+cu128" "torchaudio==2.7.0+cu128" --index-url https://download.pytorch.org/whl/cu128

pip install "xformers"

python -m pip install --upgrade pip

git pull

pip install -r requirements.txt

pip install "scikit-learn-intelex" "numpy==1.26.4" "thinc" "daal" "daal4py" "ultralytics" "setuptools==72.1.0" torchsde aiohttp spacy spandrel kornia av 

cd custom_nodes

# Deprecated nodes
# https://github.com/Randy420Marsh/comfy_controlnet_preprocessors.git

repos=("https://github.com/Randy420Marsh/ComfyUI_ADV_CLIP_emb.git"
"https://github.com/Randy420Marsh/ComfyUI_Comfyroll_CustomNodes.git"
"https://github.com/Randy420Marsh/comfyui_controlnet_aux.git"
"https://github.com/Randy420Marsh/ComfyUI_TiledKSampler.git"
"https://github.com/Randy420Marsh/ComfyUI-Custom-Scripts.git"
"https://github.com/Randy420Marsh/comfyui-dynamicprompts.git"
"https://github.com/Randy420Marsh/ComfyUI-Impact-Pack.git"
"https://github.com/Randy420Marsh/ComfyUI-Manager.git"
"https://github.com/Randy420Marsh/ComfyUI-QualityOfLifeSuit_Omar92.git"
"https://github.com/Randy420Marsh/Derfuu_ComfyUI_ModdedNodes.git"
"https://github.com/Randy420Marsh/efficiency-nodes-comfyui.git"
"https://github.com/Randy420Marsh/failfast-comfyui-extensions.git"
"https://github.com/Randy420Marsh/masquerade-nodes-comfyui.git"
"https://github.com/Randy420Marsh/nui-suite.git"
"https://github.com/Randy420Marsh/sdxl_prompt_styler.git"
"https://github.com/Randy420Marsh/SeargeSDXL.git"
"https://github.com/Randy420Marsh/was-node-suite-comfyui.git"
"https://github.com/Randy420Marsh/wlsh_nodes.git"
"https://github.com/Randy420Marsh/ComfyUI-AnimateDiff-Evolved.git"
"https://github.com/Randy420Marsh/ComfyUI_FizzNodes.git"
"https://github.com/Randy420Marsh/ComfyUI-VideoHelperSuite.git"
"https://github.com/Randy420Marsh/ComfyUI-Advanced-ControlNet.git"
"https://github.com/Randy420Marsh/human-parser-comfyui-node-in-pure-python.git"
"https://github.com/Randy420Marsh/ComfyUI-Allor.git"
"https://github.com/Randy420Marsh/ControlNet-LLLite-ComfyUI.git"
"https://github.com/Randy420Marsh/ComfyUI-WD14-Tagger.git"
"https://github.com/Randy420Marsh/ComfyUI_essentials.git"
"https://github.com/Randy420Marsh/comfy_mtb.git")

for repo_url in "${repos[@]}"; do
    repo_name=$(basename "${repo_url}" .git)

    if [ -d "${repo_name}$1" ]; then
        echo "Updating $repo_name..."
        pushd "${repo_name}$1"
        git pull
        popd
    else
        echo "Cloning $repo_name..."
        git clone "${repo_url}" "${repo_name}$1"
    fi
done

# Recursive repos
cd custom_nodes

repo_url="https://github.com/Randy420Marsh/ComfyUI_UltimateSDUpscale.git --recursive"
repo_name=$(basename "${repo_url}" .git)

if [ -d "${repo_name}$1" ]; then
    echo "Updating $repo_name..."
    pushd "${repo_name}$1"
    git pull
    popd
else
    echo "Cloning $repo_name..."
    git clone "${repo_url}" "${repo_name}$1"
fi

cd "${COMFY_UI_DIR}"

if [ -d "./wildcards" ]; then
    cd wildcards
    git reset --hard
    git pull
    echo "Updated wildcards"
else
    git clone https://github.com/Randy420Marsh/WC-SDVN.git wildcards
    echo "Downloaded/Installed wildcards"
fi

echo "Git clone finished 1/2..."

cd "${COMFY_UI_DIR}"


pip install -r "${CUSTOM_NODES_DIR}/comfyui_controlnet_aux/requirements.txt"

pip install -r "${CUSTOM_NODES_DIR}/comfyui-dynamicprompts/requirements.txt"

pip install -r "${CUSTOM_NODES_DIR}/efficiency-nodes-comfyui/requirements.txt"

pip install -r "${CUSTOM_NODES_DIR}/ComfyUI-Impact-Pack/requirements.txt"

pip install -r "${CUSTOM_NODES_DIR}/nui-suite/requirements.txt"

pip install -r "${CUSTOM_NODES_DIR}/was-node-suite-comfyui/requirements.txt"

pip install -r "${CUSTOM_NODES_DIR}/ComfyUI_FizzNodes/requirements.txt"

pip install -r "${CUSTOM_NODES_DIR}/ComfyUI-VideoHelperSuite/requirements.txt"

pip install -r "${CUSTOM_NODES_DIR}/human-parser-comfyui-node/requirements.txt"

pip install -r "${CUSTOM_NODES_DIR}/ComfyUI-Allor/requirements.txt"

pip install -r "${CUSTOM_NODES_DIR}/ComfyUI-WD14-Tagger/requirements.txt"

pip install -r "${CUSTOM_NODES_DIR}/ComfyUI_essentials/requirements.txt"

pip install -r "${CUSTOM_NODES_DIR}/custom_nodes/comfy_mtb/requirements.txt"


pip install "numpy<2.0.0,>=1.0.0" "mediapipe==0.10.21"

pip install -r requirements.txt

#fix dependencies
pip install mediapipe "av<13.0.0,>=9.0.0" "aiortc==1.9.0" "inference-gpu==0.45.1" "aiohttp<=3.10.11,>=3.9.0" "inference-gpu[yolo-world]<=0.47.0" "numpy==1.26.4" albumentations pydantic "torch==2.7.0+cu128" "torchvision==0.22.0+cu128" "torchaudio==2.7.0+cu128" --index-url https://download.pytorch.org/whl/cu128

 
echo "Update/install finished 2/2..."
