#!/usr/bin/env python3
"""
uv_update_nodes_v3.py

Cross-platform Python equivalent of uv-update-nodes_v3.sh.
Parses an HTML file containing repository links, clones/updates them,
and installs dependencies via `uv`. Compatible with Windows, macOS, and Linux.
"""

import argparse
import concurrent.futures
import os
import re
import shutil
import subprocess
import sys
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import urlparse

def log(msg=""):
    print(msg, flush=True)

def warn(msg=""):
    print(msg, file=sys.stderr, flush=True)

def die(msg):
    warn(f"ERROR: {msg}")
    sys.exit(2)

def check_dependencies():
    if not shutil.which("uv"):
        die("'uv' not found on PATH. Install uv and re-run.")
    if not shutil.which("git"):
        die("'git' not found on PATH. Install Git and re-run.")

class RepoHTMLParser(HTMLParser):
    def __init__(self):
        super().__init__()
        self.urls = set()

    def handle_starttag(self, tag, attrs):
        if tag.lower() != "a":
            return
        d = dict(attrs)
        href = d.get("href")
        if href:
            self.urls.add(href)

def extract_repos(html_path: Path) -> list:
    if not html_path.is_file():
        die(f"HTML file not found: {html_path}")
        
    text = html_path.read_text(encoding="utf-8", errors="ignore")
    p = RepoHTMLParser()
    p.feed(text)

    # Also pick up any raw URLs in text
    for m in re.findall(r'https?://[^\s"<>]+', text):
        p.urls.add(m)

    def norm(u: str) -> str:
        u = u.strip()
        u = re.sub(r'[),.]+$', '', u)
        pr = urlparse(u)
        pr = pr._replace(query="", fragment="")
        return pr.geturl()

    urls = [norm(u) for u in p.urls if re.match(r"^https?://", u.strip(), re.I)]

    out = []
    seen = set()

    for u in sorted(urls):
        if u in seen: continue
        seen.add(u)

        pr = urlparse(u)
        host = (pr.netloc or "").lower()
        path = pr.path or ""

        if u.endswith(".git"):
            out.append(u)
            continue

        if "github.com" in host:
            seg = [s for s in path.split("/") if s]
            if len(seg) >= 2:
                repo_url = pr._replace(path=f"/{seg[0]}/{seg[1]}", query="", fragment="").geturl()
                out.append(repo_url)
                continue

        seg = [s for s in path.split("/") if s]
        if len(seg) >= 2:
            repo_url = pr._replace(path=f"/{seg[0]}/{seg[1]}", query="", fragment="").geturl()
            out.append(repo_url)

    final = []
    seen2 = set()
    for u in out:
        if u not in seen2:
            seen2.add(u)
            final.append(u)

    return final

def setup_venv(args) -> dict:
    venv_dir = Path(args.venv).expanduser().resolve()
    env = os.environ.copy()

    if not args.dry_run:
        subprocess.run(["uv", "python", "pin", args.python], check=True)
        if not venv_dir.is_dir():
            subprocess.run(["uv", "venv", "--python", args.python, str(venv_dir)], check=True)

    # Mimic activation dynamically across platforms
    env["VIRTUAL_ENV"] = str(venv_dir)
    env.pop("PYTHONHOME", None) # Remove PYTHONHOME if set to avoid env pollution

    if os.name == "nt":  # Windows
        scripts_dir = venv_dir / "Scripts"
    else:  # macOS / Linux
        scripts_dir = venv_dir / "bin"

    env["PATH"] = f"{scripts_dir}{os.pathsep}{env.get('PATH', '')}"

    if not args.dry_run:
        subprocess.run(["python", "--version"], env=env, check=True)
        subprocess.run(["uv", "pip", "install", "--upgrade", "pip"], env=env, check=True)
    else:
        log(f"[DRY-RUN] Would pin python {args.python} and create/activate venv at {venv_dir}")

    return env

def clone_one(repo_url: str, custom_nodes_dir: Path, args, env_vars: dict):
    repo_name = repo_url.rstrip("/").split("/")[-1]
    if repo_name.endswith(".git"):
        repo_name = repo_name[:-4]

    dest = custom_nodes_dir / repo_name

    if dest.is_dir():
        if args.update_existing:
            if args.dry_run:
                log(f"[DRY-RUN] Would update existing repo: {repo_name} (git pull)")
            else:
                log(f"Updating {repo_name}...")
                try:
                    subprocess.run(["git", "pull", "--ff-only"], cwd=dest, check=True, env=env_vars)
                except subprocess.CalledProcessError:
                    warn(f"[WARN] git pull failed for {repo_name}; continuing.")
        else:
            log(f"[SKIP] {repo_name} (already exists)")
        return

    cmd = ["git", "clone", "--depth", str(args.depth)]
    if args.recurse_submodules:
        cmd.append("--recurse-submodules")
    cmd.extend([repo_url, str(dest)])

    if args.dry_run:
        log(f"[DRY-RUN] Would clone: {' '.join(cmd)}")
        return

    log(f"Cloning {repo_name}...")
    try:
        subprocess.run(cmd, check=True, env=env_vars)
    except subprocess.CalledProcessError:
        warn(f"[WARN] git clone failed for {repo_name}")

def install_requirements(custom_nodes_dir: Path, args, env_vars: dict):
    log(f"Scanning for requirements.txt under: {custom_nodes_dir}")
    req_files = []
    
    for path in custom_nodes_dir.rglob("requirements.txt"):
        parts = path.parts
        # Skip hidden/virtualenv directories
        if any(ignore in parts for ignore in (".git", ".venv", "venv", "__pycache__")):
            continue
        req_files.append(path)

    if not req_files:
        log("No requirements.txt files found.")
        return

    # Sort uniquely
    req_files = sorted(list(set(req_files)))
    log(f"Found {len(req_files)} requirements.txt file(s). Installing with: uv pip install -r")
    failures = []

    for req in req_files:
        log(f"\nInstalling requirements: {req}")
        if args.dry_run:
            log(f"[DRY-RUN] Would run: (cd \"{req.parent}\" && uv pip install -r \"{req.name}\")")
            continue

        try:
            subprocess.run(["uv", "pip", "install", "-r", req.name], cwd=req.parent, check=True, env=env_vars)
        except subprocess.CalledProcessError:
            warn(f"[WARN] Failed installing: {req}")
            failures.append(req)

    if failures:
        warn(f"\nOne or more requirements installs failed ({len(failures)}):")
        for f in failures:
            warn(f"  - {f}")
        warn("Continuing.")

def install_editables(custom_nodes_dir: Path, args, env_vars: dict):
    installed_any = False

    for node_root in custom_nodes_dir.iterdir():
        if not node_root.is_dir():
            continue

        has_setup = (node_root / "setup.py").is_file()
        has_pyproject = (node_root / "pyproject.toml").is_file()

        if args.install_pyproject and has_pyproject:
            installed_any = True
            log(f"\nInstalling editable (pyproject.toml): {node_root}")
            if args.dry_run:
                log(f"[DRY-RUN] Would run: (cd \"{node_root}\" && uv pip install -e .)")
            else:
                try:
                    subprocess.run(["uv", "pip", "install", "-e", "."], cwd=node_root, check=True, env=env_vars)
                except subprocess.CalledProcessError:
                    warn(f"[WARN] Editable install failed (pyproject): {node_root}")
            continue

        if args.install_setup_py and has_setup:
            installed_any = True
            log(f"\nInstalling editable (setup.py): {node_root}")
            if args.dry_run:
                log(f"[DRY-RUN] Would run: (cd \"{node_root}\" && uv pip install -e .)")
            else:
                try:
                    subprocess.run(["uv", "pip", "install", "-e", "."], cwd=node_root, check=True, env=env_vars)
                except subprocess.CalledProcessError:
                    warn(f"[WARN] Editable install failed (setup.py): {node_root}")

    if not installed_any:
        log("No editable installs performed (either flags disabled or no matching node roots found).")

def main():
    parser = argparse.ArgumentParser(description="uv-update-nodes: Parse HTML repos, clone missing, install dependencies via uv.")
    parser.add_argument("--html", type=str, default="./CustomNodeRepositories.html", help="HTML file to parse for repo URLs.")
    parser.add_argument("--custom-nodes", type=str, default="./custom_nodes", help="custom_nodes directory path.")
    parser.add_argument("--depth", type=int, default=1, help="git clone depth for new clones.")
    parser.add_argument("--update-existing", action="store_true", help="If repo folder exists, run 'git pull'.")
    parser.add_argument("--recurse-submodules", action="store_true", help="Clone with --recurse-submodules.")
    parser.add_argument("--jobs", type=int, default=1, help="Parallel clone jobs.")
    parser.add_argument("--install-setup-py", action="store_true", help="Install editable for setup.py roots.")
    parser.add_argument("--install-pyproject", action="store_true", help="Install editable for pyproject.toml roots.")
    parser.add_argument("--python", type=str, default="3.11", help="uv python pin VERSION (e.g., 3.12). Default: 3.11")
    parser.add_argument("--venv", type=str, default="./.venv", help="Virtualenv directory.")
    parser.add_argument("--dry-run", action="store_true", help="Print planned actions without cloning/installing.")
    args = parser.parse_args()

    html_path = Path(args.html).expanduser().resolve()
    custom_nodes_dir = Path(args.custom_nodes).expanduser().resolve()
    
    log(f"HTML_FILE          = {html_path}")
    log(f"CUSTOM_NODES_DIR   = {custom_nodes_dir}")
    log(f"VENV_DIR           = {Path(args.venv).expanduser().resolve()}")
    log(f"DEPTH              = {args.depth}")
    log(f"UPDATE_EXISTING    = {args.update_existing}")
    log(f"RECURSE_SUBMODULES = {args.recurse_submodules}")
    log(f"JOBS               = {args.jobs}")
    log(f"INSTALL_SETUP_PY   = {args.install_setup_py}")
    log(f"INSTALL_PYPROJECT  = {args.install_pyproject}")
    log(f"DRY_RUN            = {args.dry_run}\n")

    check_dependencies()
    env_vars = setup_venv(args)
    custom_nodes_dir.mkdir(parents=True, exist_ok=True)

    log("Parsing repositories from HTML...")
    repos = extract_repos(html_path)
    if not repos:
        die(f"No repository URLs found in {html_path}")

    log(f"Found {len(repos)} repository URL(s).\n")

    if args.jobs > 1:
        log(f"Cloning with up to {args.jobs} parallel job(s)...")
        with concurrent.futures.ThreadPoolExecutor(max_workers=args.jobs) as executor:
            futures = [executor.submit(clone_one, repo, custom_nodes_dir, args, env_vars) for repo in repos]
            concurrent.futures.wait(futures)
    else:
        for repo in repos:
            clone_one(repo, custom_nodes_dir, args, env_vars)

    log("\nRepository clone/update phase complete.\n")

    install_requirements(custom_nodes_dir, args, env_vars)
    log()

    if args.install_setup_py or args.install_pyproject:
        log("Optional editable install phase...")
        install_editables(custom_nodes_dir, args, env_vars)
        log()

    log("Running: uv pip check")
    if args.dry_run:
        log("[DRY-RUN] Would run: uv pip check")
    else:
        try:
            subprocess.run(["uv", "pip", "check"], env=env_vars, check=True)
            log("No dependency conflicts reported by 'uv pip check'.")
        except subprocess.CalledProcessError:
            warn("\nDependency conflicts were detected by 'uv pip check' (see output above).")
            warn("If you paste the output here, I can propose a concrete resolution plan (pins/overrides/constraints).")

    log("\nDone.")

if __name__ == "__main__":
    main()
