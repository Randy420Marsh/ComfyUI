#!/bin/bash

CUSTOM_NODES_DIR="$(pwd)/custom_nodes"
echo "CUSTOM_NODES_DIR = $CUSTOM_NODES_DIR"

COMFY_UI_DIR="$(pwd)"
echo "COMFY_UI_DIR = $COMFY_UI_DIR"

uv python pin 3.12

if [ -d "./.venv" ]; then
    source ./.venv/bin/activate
else
    uv venv --python3.12
    source ./.venv/bin/activate
fi

python --version

read -p "Press Enter to continue..."

uv pip install --upgrade pip

#git pull

cd custom_nodes

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
"https://github.com/Randy420Marsh/comfy_mtb.git"
"https://github.com/Randy420Marsh/ComfyUI-Yolo-World-EfficientSAM.git"  
"https://github.com/Randy420Marsh/ComfyUI-CLIPSeg.git"
"https://github.com/Randy420Marsh/ComfyUI-KJNodes.git"
"https://github.com/Randy420Marsh/ComfyUI-Impact-Subpack.git")

for repo_url in "${repos[@]}"; do
    repo_name=$(basename "${repo_url}" .git)

    if [ -d "${repo_name}" ]; then # Removed potential extra argument $1
        echo "Updating $repo_name..."
        pushd "${repo_name}" # Removed potential extra argument $1
        git pull
        popd
    else
        echo "Cloning $repo_name..."
        git clone "${repo_url}" "${repo_name}" # Removed potential extra argument $1
    fi
done

# Recursive repos
#Brainiac over here...
#cd custom_nodes

repo_url="https://github.com/Randy420Marsh/ComfyUI_UltimateSDUpscale.git"
repo_name=$(basename "${repo_url}" .git)

if [ -d "${repo_name}" ]; then # Removed potential extra argument $1
    echo "Updating $repo_name..."
    pushd "${repo_name}" # Removed potential extra argument $1
    git pull
    popd
else
    echo "Cloning $repo_name..."
    git clone --recursive "${repo_url}" "${repo_name}" # Removed potential extra argument $1
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

uv pip check

echo "Update/install finished 2/2..."
