import os
import sys
import subprocess
import shlex
import logging
from pathlib import Path
from typing import List, Union

# --- Configuration ---
# Setting up basic logging
logging.basicConfig(level=logging.INFO, format='%(levelname)s: %(message)s')

# Base directory (where the script is run)
BASE_DIR = Path.cwd()
CUSTOM_NODES_DIR = BASE_DIR / "custom_nodes"
VENV_DIR = BASE_DIR / "venv"
# Initialize with system Python, will be updated to venv Python
PYTHON_EXECUTABLE = Path(sys.executable) 

# List of GitHub repositories to clone/pull
REPOS: List[str] = [
    "https://github.com/Randy420Marsh/ComfyUI_ADV_CLIP_emb.git",
    "https://github.com/Randy420Marsh/ComfyUI_Comfyroll_CustomNodes.git",
    "https://github.com/Randy420Marsh/comfyui_controlnet_aux.git",
    "https://github.com/Randy420Marsh/ComfyUI_TiledKSampler.git",
    "https://github.com/Randy420Marsh/ComfyUI-Custom-Scripts.git",
    "https://github.com/Randy420Marsh/comfyui-dynamicprompts.git",
    "https://github.com/Randy420Marsh/ComfyUI-Impact-Pack.git",
    "https://github.com/Randy420Marsh/ComfyUI-Manager.git",
    "https://github.com/Randy420Marsh/ComfyUI-QualityOfLifeSuit_Omar92.git",
    "https://github.com/Randy420Marsh/Derfuu_ComfyUI_ModdedNodes.git",
    "https://github.com/Randy420Marsh/efficiency-nodes-comfyui.git",
    "https://github.com/Randy420Marsh/failfast-comfyui-extensions.git",
    "https://github.com/Randy420Marsh/masquerade-nodes-comfyui.git",
    "https://github.com/Randy420Marsh/nui-suite.git",
    "https://github.com/Randy420Marsh/sdxl_prompt_styler.git",
    "https://github.com/Randy420Marsh/SeargeSDXL.git",
    "https://github.com/Randy420Marsh/was-node-suite-comfyui.git",
    "https://github.com/Randy420Marsh/wlsh_nodes.git",
    "https://github.com/Randy420Marsh/ComfyUI-AnimateDiff-Evolved.git",
    "https://github.com/Randy420Marsh/ComfyUI_FizzNodes.git",
    "https://github.com/Randy420Marsh/ComfyUI-VideoHelperSuite.git",
    "https://github.com/Randy420Marsh/ComfyUI-Advanced-ControlNet.git",
    "https://github.com/Randy420Marsh/human-parser-comfyui-node-in-pure-python.git",
    "https://github.com/Randy420Marsh/ComfyUI-Allor.git",
    "https://github.com/Randy420Marsh/ControlNet-LLLite-ComfyUI.git",
    "https://github.com/Randy420Marsh/ComfyUI-WD14-Tagger.git",
    "https://github.com/Randy420Marsh/ComfyUI_essentials.git",
    "https://github.com/Randy420Marsh/comfy_mtb.git",
    "https://github.com/Randy420Marsh/ComfyUI-Yolo-World-EfficientSAM.git",
    "https://github.com/Randy420Marsh/ComfyUI-CLIPSeg.git",
    "https://github.com/Randy420Marsh/ComfyUI-KJNodes.git",
    "https://github.com/Randy420Marsh/ComfyUI-Impact-Subpack.git",
    "https://github.com/Randy420Marsh/ComfyUI_TensorRT.git",
    "https://github.com/Randy420Marsh/ComfyUI-ModelQuantizer.git",
    "https://github.com/Randy420Marsh/ComfyUI-GGUF.git",
]

# List of custom node requirements files to install
REQUIREMENTS_FILES: List[Path] = [
    CUSTOM_NODES_DIR / "comfyui_controlnet_aux/requirements.txt",
    CUSTOM_NODES_DIR / "comfyui-dynamicprompts/requirements.txt",
    CUSTOM_NODES_DIR / "efficiency-nodes-comfyui/requirements.txt",
    CUSTOM_NODES_DIR / "ComfyUI-Impact-Pack/requirements.txt",
    CUSTOM_NODES_DIR / "nui-suite/requirements.txt",
    CUSTOM_NODES_DIR / "was-node-suite-comfyui/requirements.txt",
    CUSTOM_NODES_DIR / "ComfyUI_FizzNodes/requirements.txt",
    CUSTOM_NODES_DIR / "ComfyUI-VideoHelperSuite/requirements.txt",
    CUSTOM_NODES_DIR / "human-parser-comfyui-node-in-pure-python/requirements.txt",
    CUSTOM_NODES_DIR / "ComfyUI-Allor.git/requirements.txt", # Corrected from .git to just the dir name if required
    CUSTOM_NODES_DIR / "ComfyUI-Allor/requirements.txt", # assuming the folder is 'ComfyUI-Allor'
    CUSTOM_NODES_DIR / "ComfyUI-WD14-Tagger/requirements.txt",
    CUSTOM_NODES_DIR / "ComfyUI_essentials/requirements.txt",
    CUSTOM_NODES_DIR / "comfy_mtb/requirements.txt",
    CUSTOM_NODES_DIR / "ComfyUI-Yolo-World-EfficientSAM/requirements.txt",
    CUSTOM_NODES_DIR / "ComfyUI-CLIPSeg/requirements.txt",
    CUSTOM_NODES_DIR / "ComfyUI-KJNodes/requirements.txt",
    CUSTOM_NODES_DIR / "ComfyUI_TensorRT/requirements.txt",
    CUSTOM_NODES_DIR / "ComfyUI-ModelQuantizer/requirements.txt",
    CUSTOM_NODES_DIR / "ComfyUI-GGUF/requirements.txt",
]


def run_command(command: Union[str, List[str]], cwd: Path = BASE_DIR):
    """Executes a shell command and checks for errors."""
    
    if isinstance(command, str):
        # For general shell commands, we split the string
        cmd_list = shlex.split(command, posix=False) 
    else:
        # For commands that already provide a clean list
        cmd_list = command

    # Ensure all components in the list are strings for subprocess
    cmd_list = [str(c) for c in cmd_list]
    
    logging.info(f"Running command: {' '.join(cmd_list)}")
    
    try:
        # Pass the command as a list. Do not use shell=True.
        subprocess.run(
            cmd_list, 
            check=True, 
            cwd=cwd, 
            text=True, 
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE
        )
    except subprocess.CalledProcessError as e:
        logging.error(f"Command failed with exit code {e.returncode}: {' '.join(cmd_list)}")
        logging.error(f"Stderr: {e.stderr.strip()}")
        logging.error(f"Stdout: {e.stdout.strip()}")
        sys.exit(1)
    except FileNotFoundError:
        logging.error(f"Executable not found: {cmd_list[0]}. Please ensure 'git' is installed and in your PATH, and that your Python venv path is correct.")
        sys.exit(1)


def setup_venv():
    """Creates and sets the path for the virtual environment's Python executable."""
    global PYTHON_EXECUTABLE

    if not VENV_DIR.exists():
        logging.info("Creating virtual environment...")
        # Use the system's Python to create the venv.
        run_command(f"{sys.executable} -m venv {VENV_DIR.name}")

    # Determine the correct Python executable inside the venv
    if sys.platform == "win32":
        PYTHON_EXECUTABLE = VENV_DIR / "Scripts" / "python.exe"
    else:
        PYTHON_EXECUTABLE = VENV_DIR / "bin" / "python"

    # Crucial step: Check if the venv Python exists after creation/discovery
    if not PYTHON_EXECUTABLE.exists():
        logging.error(f"Virtual environment Python executable not found at {PYTHON_EXECUTABLE}. Exiting.")
        sys.exit(1)
    
    logging.info(f"Using venv's Python: {PYTHON_EXECUTABLE}")

def pip_install(packages: str):
    """
    Installs packages using the venv's pip.
    Handles '-r requirements.txt' paths by passing the path as a clean argument.
    """
    cmd = [str(PYTHON_EXECUTABLE), "-m", "pip", "install", "--upgrade"]
    
    # Use shlex.split for initial options/packages 
    args = shlex.split(packages, posix=False) 
    
    # Check for the requirements file flag
    if "-r" in args:
        # Find all instances of '-r' and ensure their paths are handled cleanly
        new_args = []
        skip_next = False
        for i, arg in enumerate(args):
            if skip_next:
                skip_next = False
                continue

            if arg == "-r" and i + 1 < len(args):
                # Append the -r flag
                new_args.append("-r")
                
                # Append the path itself, ensuring it's a Path object converted to a string.
                # Strip quotes just in case, though they shouldn't be in the input now.
                req_file_path = args[i + 1].strip("'\"") 
                new_args.append(str(Path(req_file_path)))
                skip_next = True
            else:
                new_args.append(arg)
        
        cmd.extend(new_args)
    else:
        # For standard package installation
        cmd.extend(args)
        
    run_command(cmd)

def pip_uninstall(packages: str):
    """Uninstalls packages using the venv's pip with '-y'."""
    cmd = [str(PYTHON_EXECUTABLE), "-m", "pip", "uninstall", "-y"]
    cmd.extend(shlex.split(packages, posix=False))
    run_command(cmd)

def process_repo(repo_url: str, is_recursive: bool = False):
    """Clones or updates a single repository."""
    repo_name = Path(repo_url).stem
    repo_path = CUSTOM_NODES_DIR / repo_name
    
    os.makedirs(CUSTOM_NODES_DIR, exist_ok=True) # Ensure custom_nodes exists

    if repo_path.exists():
        logging.info(f"Updating {repo_name}...")
        run_command("git pull", cwd=repo_path) 
    else:
        logging.info(f"Cloning {repo_name}...")
        recursive_flag = "--recursive" if is_recursive else ""
        run_command(f"git clone {repo_url} {recursive_flag} {repo_name}", cwd=CUSTOM_NODES_DIR)

def main():
    logging.info(f"COMFY_UI_DIR = {BASE_DIR}")
    logging.info(f"CUSTOM_NODES_DIR = {CUSTOM_NODES_DIR}")
    print()
    input("Press Enter to continue...")
    print()

    # --- Virtual Environment Setup ---
    setup_venv()

    # --- Core Updates (Run in BASE_DIR) ---
    logging.info("Upgrading pip...")
    pip_install("pip") 

    logging.info("Pulling ComfyUI repository changes...")
    run_command("git pull")

    logging.info("Installing/Upgrading base requirements.txt...")
    pip_install("-r requirements.txt")

    # --- Custom Nodes Update (Phase 1: Git) ---
    logging.info("\n--- Custom Nodes Update (Phase 1) ---")
    for repo_url in REPOS:
        process_repo(repo_url)

    # Recursive repo (ComfyUI_UltimateSDUpscale)
    repo_url_recursive = "https://github.com/Randy420Marsh/ComfyUI_UltimateSDUpscale.git"
    process_repo(repo_url_recursive, is_recursive=True)

    # --- Wildcards Update ---
    wildcards_dir = BASE_DIR / "wildcards"
    logging.info("\n--- Wildcards Update ---")
    if wildcards_dir.exists():
        logging.info("Updating wildcards...")
        run_command("git reset --hard", cwd=wildcards_dir)
        run_command("git pull", cwd=wildcards_dir)
    else:
        logging.info("Cloning wildcards...")
        run_command("git clone https://github.com/Randy420Marsh/WC-SDVN.git wildcards")
        
    logging.info("Git clone finished 1/2...")

    # --- Custom Nodes Requirements Install (Phase 2: Pip) ---
    logging.info("\n--- Custom Nodes Requirements Install ---")
    for req_file in REQUIREMENTS_FILES:
        if req_file.exists():
            logging.info(f"Installing requirements for {req_file.parent.name}...")
            # *** FIX APPLIED HERE: NO QUOTES around {req_file} ***
            # The pip_install function now correctly converts the path to a string argument.
            pip_install(f"-r {req_file}")
        else:
            logging.warning(f"Requirements file not found for {req_file.parent.name}: {req_file}")
            
    # Impact-Subpack special install
    logging.info("Running install.py for ComfyUI-Impact-Subpack...")
    impact_subpack_dir = CUSTOM_NODES_DIR / "ComfyUI-Impact-Subpack"
    if impact_subpack_dir.exists():
        # Call install.py using the venv's python as a list command
        run_command([str(PYTHON_EXECUTABLE), "install.py"], cwd=impact_subpack_dir)
        # *** FIX APPLIED HERE: NO QUOTES around path ***
        pip_install(f"-r {impact_subpack_dir / 'requirements.txt'}")
    else:
        logging.warning("ComfyUI-Impact-Subpack directory not found. Skipping install.py.")

    # --- Core Dependency Management ---
    logging.info("\n--- Core Dependency Management ---")
    
    # Uninstall onnxruntime packages
    pip_uninstall("onnxruntime-gpu onnxruntime")

    # Uninstall torch packages
    pip_uninstall("torch torchvision torchaudio xformers")

    # Install specific torch packages with cu128 index-url
    logging.info("Installing PyTorch with CUDA 12.8 support...")
    
    # Constructed as a list command to ensure correct argument passing
    torch_cmd = [
        str(PYTHON_EXECUTABLE), 
        "-m", "pip", "install", 
        "--upgrade", 
        "torch==2.7.1+cu128", 
        "torchaudio==2.7.1+cu128", 
        "torchvision==0.22.1+cu128", 
        "--index-url", 
        "https://download.pytorch.org/whl/cu128"
    ]
    run_command(torch_cmd)

    # Install win-requirements.txt
    logging.info("Installing win-requirements.txt...")
    pip_install("-r win-requirements.txt")
    
    logging.info("Update/install finished 2/2...")


if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        logging.error(f"An unexpected error occurred: {e}")
    finally:
        input("Press Enter to exit...")