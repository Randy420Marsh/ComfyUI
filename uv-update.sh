#!/bin/bash

CUSTOM_NODES_DIR="$(pwd)/custom_nodes"
echo "CUSTOM_NODES_DIR = $CUSTOM_NODES_DIR"

COMFY_UI_DIR="$(pwd)"
echo "COMFY_UI_DIR = $COMFY_UI_DIR"

uv python pin 3.12

if [ -d "./.venv" ]; then
    source ./.venv/bin/activate
else
    uv venv --python 3.12
    source ./.venv/bin/activate
fi

python --version

read -p "Press Enter to continue..."

uv pip install --upgrade pip

#git pull

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
cd custom_nodes

repo_url="https://github.com/Randy420Marsh/ComfyUI_UltimateSDUpscale.git --recursive"
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


pip uninstall onnxruntime-gpu onnxruntime -y

pip uninstall -y torch torchvision torchaudio xformers

uv pip install -r "${CUSTOM_NODES_DIR}/ComfyUI-Manager/requirements.txt"

uv pip install -r "${CUSTOM_NODES_DIR}/comfyui_controlnet_aux/requirements.txt"
uv pip install -r "${CUSTOM_NODES_DIR}/comfyui-dynamicprompts/requirements.txt"
uv pip install -r "${CUSTOM_NODES_DIR}/efficiency-nodes-comfyui/requirements.txt"
uv pip install -r "${CUSTOM_NODES_DIR}/ComfyUI-Impact-Pack/requirements.txt"
uv pip install -r "${CUSTOM_NODES_DIR}/nui-suite/requirements.txt"
uv pip install -r "${CUSTOM_NODES_DIR}/was-node-suite-comfyui/requirements.txt"
uv pip install -r "${CUSTOM_NODES_DIR}/ComfyUI_FizzNodes/requirements.txt"
uv pip install -r "${CUSTOM_NODES_DIR}/ComfyUI-VideoHelperSuite/requirements.txt"
uv pip install -r "${CUSTOM_NODES_DIR}/human-parser-comfyui-node-in-pure-python/requirements.txt"
uv pip install -r "${CUSTOM_NODES_DIR}/ComfyUI-Allor/requirements.txt"
uv pip install -r "${CUSTOM_NODES_DIR}/ComfyUI-WD14-Tagger/requirements.txt"
uv pip install -r "${CUSTOM_NODES_DIR}/ComfyUI_essentials/requirements.txt"
uv pip install -r "${CUSTOM_NODES_DIR}/comfy_mtb/requirements.txt"
uv pip install -r "${CUSTOM_NODES_DIR}/ComfyUI-Yolo-World-EfficientSAM/requirements.txt"
uv pip install -r "${CUSTOM_NODES_DIR}/ComfyUI-CLIPSeg/requirements.txt"
uv pip install -r "${CUSTOM_NODES_DIR}/ComfyUI-KJNodes/requirements.txt"

uv pip install -r "${CUSTOM_NODES_DIR}/RES4LYF/requirements.txt"

#uv pip install -r "${CUSTOM_NODES_DIR}/ComfyUI_Sonic/requirements.txt"

uv pip install -r "${CUSTOM_NODES_DIR}/ComfyUI_LayerStyle/requirements.txt"


cd ${CUSTOM_NODES_DIR}/ComfyUI-Impact-Subpack
uv pip install -r requirements.txt
#uv python -s install.py

cd "${COMFY_UI_DIR}"

uv pip install -r requirements.txt

uv pip install --upgrade "inference[sam]" "inference[grounding-dino]" "inference[transformers]" "mediapipe" "Pillow<10,>=9.0.0" "scikit-learn-intelex" "thinc" "numpy==1.26.4"  "daal" "daal4py" "ultralytics" "setuptools" "aiortc~=1.9.0" "av==12.3.0"  "albumentations==1.4.4" "pydantic>=2.9.2" "torchsde" "aiohttp<=3.10.11,>=3.9.0" "spandrel" "kornia" "pynvml" "onnxruntime==1.19.2" "onnxruntime-gpu==1.19.2" "opencv-python<=4.10.0.84,>=4.8.1.78" "peft" "bitsandbytes" "pycuda" "spacy" "shapely"

#uv pip install --upgrade "torch==2.7.1+cu128" "torchaudio==2.7.1+cu128" "torchvision==0.22.1+cu128" "xformers" --index-url https://download.pytorch.org/whl/cu128

uv pip install --upgrade "torch" "torchaudio" "torchvision" "xformers" --index-url https://download.pytorch.org/whl/cu128

uv pip install --upgrade "numpy==1.26.4" "Pillow<10,>=9.0.0" "networkx<=3.4" "inference-gpu" "inference" "protobuf" "mediapipe" "pydantic" "pyparsing" "shapely" "dghs-imgutils" "scikit-learn"  "diffusers" "dashscope" "llama-cpp-python" "piexif" "chardet" "dghs-imgutils[gpu]" "pycryptodome" "aiortc" "aiohttp" "mediapipe" "pyrfc6266" "opencv-contrib-python" "albucore" "rembg" "albumentations" "shapely" "supervision" "inference-gpu[yolo-world]<=0.47.0"

 uv pip install --upgrade "numpy===1.26.4" inference inference-gpu mediapipe shapely pyparsing protobuf dghs-imgutils pyrfc6266


uv pip check

echo "Update/install finished 2/2..."
