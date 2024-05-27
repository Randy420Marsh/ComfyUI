#!/bin/bash

echo "This script is updated 2024..."

git pull

python_cmd="python3.10"

CUSTOM_NODES_DIR="$(pwd)/custom_nodes"

echo "CUSTOM_NODES_DIR = $CUSTOM_NODES_DIR"

COMFY_UI_DIR="$(pwd)"
echo "COMFY_UI_DIR = $COMFY_UI_DIR"

# Check for NVIDIA GPU
gpu_info=$(lspci | grep -i nvidia)

if [ -n "$gpu_info" ]; then
    echo "NVIDIA GPU detected: $gpu_info"
else
    echo "No NVIDIA GPU detected."
fi

# Prompt user for choice
while true; do
    read -p "Do you want to update the GPU or CPU version (G/C)? " user_choice

    case $user_choice in
        [Gg]* )
            venv_dir="venv"
            install_cmd="pip install torch torchvision --index-url https://download.pytorch.org/whl/cu118"
            install_xformers=true
            break
            ;;
        [Cc]* )
            venv_dir="venv-cpu"
            install_cmd="pip install torch torchvision --index-url https://download.pytorch.org/whl/cpu"
            install_xformers=false
            break
            ;;
        * )
            echo "Invalid choice. Please enter G for GPU version or C for CPU version."
            ;;
    esac
done

$python_cmd --version

read -p "Press Enter to continue..."

sudo apt install -y libjemalloc-dev intel-mkl gperf

# Create and activate virtual environment
if [ -d "./$venv_dir" ]; then
    source ./$venv_dir/bin/activate
else
    $python_cmd -m venv $venv_dir
    source ./$venv_dir/bin/activate
fi

$python_cmd -m pip install --upgrade pip

cd "${COMFY_UI_DIR}"

pip uninstall -y torch torchvision xformers

# Install chosen version of torch and torchvision
$install_cmd

pip install -r requirements.txt

if [ "$install_xformers" = true ]; then
    pip install xformers
fi

cd "$CUSTOM_NODES_DIR"

repos=(
    "https://github.com/Randy420Marsh/ComfyUI_ADV_CLIP_emb.git"
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
)

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
