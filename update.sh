#!/bin/bash

CUSTOM_NODES_DIR="$(pwd)/custom_nodes"
echo "CUSTOM_NODES_DIR = $CUSTOM_NODES_DIR"

COMFY_UI_DIR="$(pwd)"
echo "COMFY_UI_DIR = $COMFY_UI_DIR"

if [ -d "./venv" ]; then
    source ./venv/bin/activate
else
    python3 -m venv venv
    source ./venv/bin/activate
fi

python --version

read -p "Press Enter to continue..."

pip uninstall torch torchvision xformers

pip install torch torchvision --index-url https://download.pytorch.org/whl/cu118

pip install xformers

python -m pip install --upgrade pip

git pull

pip install -r requirements.txt

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
"https://github.com/Randy420Marsh/wlsh_nodes.git")

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
pip install -r "${CUSTOM_NODES_DIR}/nui-suite/requirements.txt"
pip install -r "${CUSTOM_NODES_DIR}/was-node-suite-comfyui/requirements.txt"

echo "Update/install finished 2/2..."
