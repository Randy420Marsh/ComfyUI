#!/usr/bin/env python3
"""
Clone or UPDATE all git repositories from an HTML <a href="..."> list into custom_nodes.

Behavior:
- If folder doesn't exist → git clone --depth 1
- If folder exists     → git pull (updates to latest code)
- --install flag (OFF by default) runs pip install -r requirements.txt after update/clone
- Safe for parallel jobs (--jobs 8 is fine)

Example:
  python clone_custom_nodes.py --html CustomNodeRepositories.html --target ./custom_nodes --jobs 8
  python clone_custom_nodes.py --html CustomNodeRepositories.html --target ./custom_nodes --jobs 1 --install
"""

from __future__ import annotations

import argparse
import os
import re
import shutil
import subprocess
import sys
from dataclasses import dataclass
from html.parser import HTMLParser
from pathlib import Path
from typing import List, Optional
from urllib.parse import urlparse
from concurrent.futures import ThreadPoolExecutor, as_completed


@dataclass(frozen=True)
class Repo:
    name: str
    url: str


class AnchorRepoParser(HTMLParser):
    def __init__(self) -> None:
        super().__init__()
        self._in_a = False
        self._current_href: Optional[str] = None
        self._current_text_parts: List[str] = []
        self.repos: List[Repo] = []

    def handle_starttag(self, tag: str, attrs):
        if tag.lower() != "a":
            return
        href = None
        for k, v in attrs:
            if k.lower() == "href":
                href = v
                break
        if href:
            self._in_a = True
            self._current_href = href
            self._current_text_parts = []

    def handle_endtag(self, tag: str):
        if tag.lower() != "a":
            return
        if self._in_a and self._current_href:
            text = "".join(self._current_text_parts).strip()
            url = self._current_href.strip()
            name = text or derive_repo_name_from_url(url)
            name = sanitize_dirname(name)
            self.repos.append(Repo(name=name, url=url))

        self._in_a = False
        self._current_href = None
        self._current_text_parts = []

    def handle_data(self, data: str):
        if self._in_a:
            self._current_text_parts.append(data)


def sanitize_dirname(name: str) -> str:
    name = name.strip()
    name = name.replace("/", "_").replace("\\", "_")
    name = re.sub(r'[:*?"<>|]', "_", name)
    name = re.sub(r"\s+", " ", name).strip()
    return name


def derive_repo_name_from_url(url: str) -> str:
    try:
        p = urlparse(url)
        last = (p.path or "").rstrip("/").split("/")[-1]
        if last.endswith(".git"):
            last = last[:-4]
        return last or "repo"
    except Exception:
        return "repo"


def load_repos_from_html(html_path: Path) -> List[Repo]:
    html_text = html_path.read_text(encoding="utf-8", errors="replace")
    parser = AnchorRepoParser()
    parser.feed(html_text)

    repos = []
    seen = set()
    for r in parser.repos:
        if not re.match(r"^https?://", r.url, re.IGNORECASE):
            continue
        key = (r.name, r.url)
        if key in seen:
            continue
        seen.add(key)
        repos.append(r)
    return repos


def ensure_git_available() -> None:
    try:
        subprocess.run(["git", "--version"], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except Exception:
        raise RuntimeError("git was not found on PATH. Please install Git and try again.")


def git_update_repo(repo: Repo, target_root: Path, depth: int, force: bool,
                    recurse_submodules: bool, dry_run: bool, install_requirements: bool) -> str:
    dest = target_root / repo.name

    # === FORCE: delete and re-clone ===
    if dest.exists() and force:
        if dry_run:
            return f"[DRY-RUN] Would remove existing: {dest}"
        shutil.rmtree(dest)

    # === UPDATE existing repo ===
    if dest.exists():
        if not (dest / ".git").exists():
            return f"[SKIP] {repo.name} (exists but not a git repository)"

        if dry_run:
            return f"[DRY-RUN] Would git pull in: {dest}"

        print(f"[PULL] Updating {repo.name}...")
        cmd = ["git", "pull"]
        if recurse_submodules:
            cmd.append("--recurse-submodules")
        p = subprocess.run(cmd, cwd=dest, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)

        if p.returncode != 0:
            return f"[FAIL] {repo.name} (git pull failed)\n{p.stdout}"

        action = "UPDATED"

    # === CLONE new repo ===
    else:
        if dry_run:
            cmd = ["git", "clone", "--depth", str(depth)]
            if recurse_submodules:
                cmd.append("--recurse-submodules")
            cmd.extend([repo.url, str(dest)])
            return f"[DRY-RUN] {' '.join(cmd)}"

        cmd = ["git", "clone", "--depth", str(depth)]
        if recurse_submodules:
            cmd.append("--recurse-submodules")
        cmd.extend([repo.url, str(dest)])

        p = subprocess.run(cmd, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        if p.returncode != 0:
            if dest.exists():
                shutil.rmtree(dest, ignore_errors=True)
            raise RuntimeError(f"Clone failed for {repo.url} -> {dest}\n{p.stdout}")

        action = "CLONED"

    # === Optional requirements install ===
    if install_requirements:
        req_file = dest / "requirements.txt"
        if req_file.exists():
            print(f"[INSTALL] Installing requirements for {repo.name}...")
            try:
                subprocess.run(
                    [sys.executable, "-m", "pip", "install", "-r", str(req_file)],
                    check=True,
                    cwd=dest,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.STDOUT,
                    text=True,
                )
                return f"[OK] {repo.name} {action} + requirements installed"
            except Exception as e:
                return f"[OK] {repo.name} {action} (requirements failed: {e})"
        else:
            return f"[OK] {repo.name} {action} (no requirements.txt)"

    return f"[OK] {repo.name} {action}"


def main() -> int:
    ap = argparse.ArgumentParser(description="Clone or UPDATE ComfyUI custom nodes from HTML list.")
    ap.add_argument("--html", required=True, type=Path, help="Path to the HTML file containing <a href=...> links.")
    ap.add_argument("--target", default=Path("./custom_nodes"), type=Path, help="Target custom_nodes directory.")
    ap.add_argument("--depth", default=1, type=int, help="Shallow clone depth (default: 1).")
    ap.add_argument("--force", action="store_true", help="Delete existing folders and re-clone fresh.")
    ap.add_argument("--recurse-submodules", action="store_true", help="Also fetch submodules.")
    ap.add_argument("--jobs", default=1, type=int, help="Parallel jobs (default: 1, recommended 8 for pull).")
    ap.add_argument("--dry-run", action="store_true", help="Print actions without doing anything.")
    ap.add_argument("--install", action="store_true", default=False,
                    help="After update/clone, run `pip install -r requirements.txt` (default: OFF)")
    args = ap.parse_args()

    ensure_git_available()

    if not args.html.exists():
        print(f"ERROR: HTML file not found: {args.html}", file=sys.stderr)
        return 2

    repos = load_repos_from_html(args.html)
    if not repos:
        print("ERROR: No repository links found in the HTML file.", file=sys.stderr)
        return 3

    args.target.mkdir(parents=True, exist_ok=True)

    print(f"Found {len(repos)} repositories in {args.html}")
    print(f"Target: {args.target.resolve()}")
    print(f"Mode: {'FORCE re-clone' if args.force else 'Update (pull) if exists'} | jobs: {args.jobs} | install: {args.install}\n")

    if args.install and args.jobs > 1:
        print("⚠️  WARNING: --install + high --jobs can cause pip conflicts. Using --jobs 1 for safety.\n")

    ok = skip = fail = 0
    failures: List[str] = []

    # Force sequential mode when installing requirements
    use_parallel = args.jobs > 1 and not args.install

    if not use_parallel:
        for r in repos:
            try:
                msg = git_update_repo(r, args.target, args.depth, args.force,
                                       args.recurse_submodules, args.dry_run, args.install)
                print(msg)
                if msg.startswith("[OK]"):
                    ok += 1
                elif msg.startswith("[SKIP]"):
                    skip += 1
            except Exception as e:
                fail += 1
                failures.append(f"{r.name}: {e}")
                print(f"[FAIL] {r.name}", file=sys.stderr)
    else:
        with ThreadPoolExecutor(max_workers=args.jobs) as ex:
            fut_map = {
                ex.submit(git_update_repo, r, args.target, args.depth, args.force,
                          args.recurse_submodules, args.dry_run, args.install): r
                for r in repos
            }
            for fut in as_completed(fut_map):
                r = fut_map[fut]
                try:
                    msg = fut.result()
                    print(msg)
                    if msg.startswith("[OK]"):
                        ok += 1
                    elif msg.startswith("[SKIP]"):
                        skip += 1
                except Exception as e:
                    fail += 1
                    failures.append(f"{r.name}: {e}")
                    print(f"[FAIL] {r.name}", file=sys.stderr)

    print("\nSummary")
    print(f"  OK:   {ok}")
    print(f"  SKIP: {skip}")
    print(f"  FAIL: {fail}")

    if failures:
        print("\nFailures:", file=sys.stderr)
        for f in failures:
            print(f"- {f}", file=sys.stderr)
        return 1

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
