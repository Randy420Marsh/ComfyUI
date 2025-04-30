import os
import requests
from tqdm import tqdm
import hashlib

MODELS = [
    {
        "filename": "sd_xl_base_1.0_0.9vae.safetensors",
        "url": "https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0/resolve/main/",
        "folder": "Stable-diffusion",
        "importance": "required",
    },
    {
        "filename": "sd_xl_refiner_1.0_0.9vae.safetensors",
        "url": "https://huggingface.co/stabilityai/stable-diffusion-xl-refiner-1.0/resolve/main/",
        "folder": "Stable-diffusion",
        "importance": "recommended",
    },
    {
        "filename": "sdxl_vae.safetensors",
        "url": "https://huggingface.co/madebyollin/sdxl-vae-fp16-fix/resolve/main/",
        "folder": "vae",
        "importance": "optional",
    },
    {
        "filename": "sd_xl_offset_example-lora_1.0.safetensors",
        "url": "https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0/resolve/main/",
        "folder": "loras",
        "importance": "optional",
    },
    {
        "filename": "4x-UltraSharp.pth",
        "url": "https://huggingface.co/uwg/upscaler/resolve/main/ESRGAN/",
        "folder": "upscale_models",
        "importance": "recommended",
    },
    {
        "filename": "4x_NMKD-Siax_200k.pth",
        "url": "https://huggingface.co/uwg/upscaler/resolve/main/ESRGAN/",
        "folder": "upscale_models",
        "importance": "recommended",
    },
    {
        "filename": "4x_Nickelback_70000G.pth",
        "url": "https://huggingface.co/uwg/upscaler/resolve/main/ESRGAN/",
        "folder": "upscale_models",
        "importance": "recommended",
    },
    {
        "filename": "1x-ITF-SkinDiffDetail-Lite-v1.pth",
        "url": "https://huggingface.co/uwg/upscaler/resolve/main/ESRGAN/",
        "folder": "upscale_models",
        "importance": "optional",
    },
    {
        "filename": "ControlNetHED.pth",
        "url": "https://huggingface.co/lllyasviel/Annotators/resolve/main/",
        "folder": "annotators",
        "importance": "required",
    },
    {
        "filename": "res101.pth",
        "url": "https://huggingface.co/lllyasviel/Annotators/resolve/main/",
        "folder": "annotators",
        "importance": "required",
    },
    {
        "filename": "clip_vision_g.safetensors",
        "url": "https://huggingface.co/stabilityai/control-lora/resolve/main/revision/",
        "folder": "clip_vision",
        "importance": "recommended",
    },
    {
        "filename": "control-lora-canny-rank256.safetensors",
        "url": "https://huggingface.co/stabilityai/control-lora/resolve/main/control-LoRAs-rank256/",
        "folder": "controlnet",
        "importance": "recommended",
    },
    {
        "filename": "control-lora-depth-rank256.safetensors",
        "url": "https://huggingface.co/stabilityai/control-lora/resolve/main/control-LoRAs-rank256/",
        "folder": "controlnet",
        "importance": "recommended",
    },
    {
        "filename": "control-lora-recolor-rank256.safetensors",
        "url": "https://huggingface.co/stabilityai/control-lora/resolve/main/control-LoRAs-rank256/",
        "folder": "controlnet",
        "importance": "recommended",
    },
    {
        "filename": "control-lora-sketch-rank256.safetensors",
        "url": "https://huggingface.co/stabilityai/control-lora/resolve/main/control-LoRAs-rank256/",
        "folder": "controlnet",
        "importance": "recommended",
    },
]

base_path = "/media/john/20TB/AI/stable_diffusion_models_and_vae/models/"

def calculate_sha256(filepath):
    hasher = hashlib.sha256()
    try:
        with open(filepath, 'rb') as file:
            while True:
                chunk = file.read(4096)
                if not chunk:
                    break
                hasher.update(chunk)
        return hasher.hexdigest()
    except FileNotFoundError:
        return None

for model in MODELS:
    filename = model["filename"]
    url = model["url"]
    folder = model["folder"]
    full_url = os.path.join(url, filename)
    download_path = os.path.join(base_path, folder)
    os.makedirs(download_path, exist_ok=True)
    filepath = os.path.join(download_path, filename)

    print(f"Processing {filename}...")

    if os.path.exists(filepath):
        print(f"File {filename} already exists at {filepath}.")
        existing_sha256 = calculate_sha256(filepath)
        file_size_bytes = os.path.getsize(filepath)
        file_size_mb = file_size_bytes / (1024 * 1024)
        print(f"Existing file size: {file_size_mb:.2f} MB")
        print(f"Existing file SHA256: {existing_sha256}")
    else:
        print(f"Downloading {filename} to {filepath}...")
        try:
            response = requests.get(full_url, stream=True)
            response.raise_for_status()  # Raise an exception for bad status codes

            total_size = int(response.headers.get('content-length', 0))
            block_size = 1024
            tqdm_iterator = tqdm(response.iter_content(block_size), total=total_size // block_size, unit='KB', unit_scale=False)

            with open(filepath, 'wb') as file:
                for data in tqdm_iterator:
                    file.write(data)
            print(f"Successfully downloaded {filename}!")

            downloaded_sha256 = calculate_sha256(filepath)
            file_size_bytes = os.path.getsize(filepath)
            file_size_mb = file_size_bytes / (1024 * 1024)
            print(f"Downloaded file size: {file_size_mb:.2f} MB")
            print(f"Downloaded file SHA256: {downloaded_sha256}")

        except requests.exceptions.RequestException as e:
            print(f"Error downloading {filename}: {e}")
    print("-" * 30)

print("All downloads and checks complete!")
