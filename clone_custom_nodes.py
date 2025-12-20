#!/usr/bin/env python3
"""
Clone all git repositories referenced in an HTML <a href="..."> list into a custom_nodes directory,
using shallow clones: `git clone --depth 1`.

Example:
  python clone_custom_nodes.py --html CustomNodeRepositories.html --target ./custom_nodes

Notes:
- Existing destination folders are skipped by default.
- Use --force to delete an existing folder and re-clone.
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
    """
    Extract <a href="...">TEXT</a> pairs.
    """
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
    """
    Make a conservative filesystem-friendly directory name.
    """
    name = name.strip()
    # Replace path separators with underscore
    name = name.replace("/", "_").replace("\\", "_")
    # Remove characters that are commonly problematic on Windows/macOS/Linux
    name = re.sub(r'[:*?"<>|]', "_", name)
    # Collapse whitespace
    name = re.sub(r"\s+", " ", name).strip()
    return name


def derive_repo_name_from_url(url: str) -> str:
    """
    Derive a folder name from the URL path, e.g. .../owner/repo(.git) -> repo
    """
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

    # Keep only plausible git/http(s) URLs (your file uses GitHub https links)
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
        subprocess.run(
            ["git", "--version"],
            check=True,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
    except Exception:
        raise RuntimeError("git was not found on PATH. Please install Git and try again.")


def git_clone(repo: Repo, target_root: Path, depth: int, force: bool, recurse_submodules: bool, dry_run: bool) -> str:
    dest = target_root / repo.name

    if dest.exists():
        if force:
            if dry_run:
                return f"[DRY-RUN] Would remove existing: {dest}"
            shutil.rmtree(dest)
        else:
            return f"[SKIP] {repo.name} (already exists: {dest})"

    cmd = ["git", "clone", "--depth", str(depth)]
    if recurse_submodules:
        cmd.append("--recurse-submodules")
    cmd.extend([repo.url, str(dest)])

    if dry_run:
        return f"[DRY-RUN] {' '.join(cmd)}"

    p = subprocess.run(cmd, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    if p.returncode != 0:
        # Clean up partial directory if clone failed
        if dest.exists():
            shutil.rmtree(dest, ignore_errors=True)
        raise RuntimeError(f"Clone failed for {repo.url} -> {dest}\n{p.stdout}")

    return f"[OK] {repo.name}"


def main() -> int:
    ap = argparse.ArgumentParser(description="Clone repositories from an HTML list into custom_nodes (shallow).")
    ap.add_argument("--html", required=True, type=Path, help="Path to the HTML file containing <a href=...> links.")
    ap.add_argument("--target", default=Path("./custom_nodes"), type=Path, help="Target custom_nodes directory.")
    ap.add_argument("--depth", default=1, type=int, help="Shallow clone depth (default: 1).")
    ap.add_argument("--force", action="store_true", help="Delete existing repo folders and re-clone.")
    ap.add_argument("--recurse-submodules", action="store_true", help="Also fetch submodules (still shallow).")
    ap.add_argument("--jobs", default=1, type=int, help="Parallel clone jobs (default: 1).")
    ap.add_argument("--dry-run", action="store_true", help="Print actions without cloning.")
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
    print(f"Target directory: {args.target.resolve()}")
    print(f"Clone depth: {args.depth} | jobs: {args.jobs} | force: {args.force} | dry-run: {args.dry_run}\n")

    ok = skip = fail = 0
    failures: List[str] = []

    if args.jobs <= 1:
        for r in repos:
            try:
                msg = git_clone(r, args.target, args.depth, args.force, args.recurse_submodules, args.dry_run)
                print(msg)
                if msg.startswith("[OK]"):
                    ok += 1
                elif msg.startswith("[SKIP]"):
                    skip += 1
            except Exception as e:
                fail += 1
                failures.append(f"{r.name}: {e}")
                print(f"[FAIL] {r.name} ({r.url})", file=sys.stderr)
    else:
        with ThreadPoolExecutor(max_workers=args.jobs) as ex:
            fut_map = {
                ex.submit(git_clone, r, args.target, args.depth, args.force, args.recurse_submodules, args.dry_run): r
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
                    print(f"[FAIL] {r.name} ({r.url})", file=sys.stderr)

    print("\nSummary")
    print(f"  OK:   {ok}")
    print(f"  SKIP: {skip}")
    print(f"  FAIL: {fail}")

    if failures:
        print("\nFailures (details):", file=sys.stderr)
        for f in failures:
            print(f"- {f}", file=sys.stderr)
        return 1

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
