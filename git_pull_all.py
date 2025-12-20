import os
import subprocess
from pathlib import Path
from typing import Tuple, Optional, List, Dict
import argparse


# ---------------------------------------------------------
# Utility: Run git commands safely
# ---------------------------------------------------------
def run_git_cmd(args: List[str], repo_path: Path, timeout: int = 30):
    return subprocess.run(
        ["git"] + args,
        cwd=repo_path,
        capture_output=True,
        text=True,
        timeout=timeout,
        check=False
    )


# ---------------------------------------------------------
# Git status helpers
# ---------------------------------------------------------
def get_current_branch(repo_path: Path) -> Optional[str]:
    cmd = run_git_cmd(["rev-parse", "--abbrev-ref", "HEAD"], repo_path)
    if cmd.returncode == 0:
        return cmd.stdout.strip()
    return None


def repo_is_dirty(repo_path: Path) -> bool:
    """True if uncommitted changes exist."""
    status = run_git_cmd(["status", "--porcelain"], repo_path)
    if status.returncode != 0:
        return True
    return bool(status.stdout.strip())


def repo_has_conflicts(repo_path: Path) -> bool:
    """True if merge conflicts exist."""
    diff = run_git_cmd(["diff", "--name-only", "--diff-filter=U"], repo_path)
    if diff.returncode != 0:
        return True
    return bool(diff.stdout.strip())


def list_conflict_files(repo_path: Path) -> List[str]:
    diff = run_git_cmd(["diff", "--name-only", "--diff-filter=U"], repo_path)
    if diff.returncode != 0:
        return []
    return [line.strip() for line in diff.stdout.splitlines() if line.strip()]


def show_local_vs_remote_diff(repo_path: Path, branch: str):
    """Print local changes + diff vs remote."""
    print(f"\n--- Local vs Remote Diff for {repo_path} ---")

    print("\n[LOCAL STATUS]")
    status = run_git_cmd(["status"], repo_path)
    print(status.stdout if status.stdout else "No local modifications.")

    print(f"\n[REMOTE DIFF: origin/{branch}..HEAD]")
    diff = run_git_cmd(["diff", f"origin/{branch}..HEAD"], repo_path)
    print(diff.stdout if diff.stdout else "No differences.")

    print("\n[COMMITS AHEAD/BEHIND]")
    ahead = run_git_cmd(
        ["rev-list", "--left-right", "--count", f"origin/{branch}...HEAD"],
        repo_path
    )
    if ahead.returncode == 0:
        left, right = ahead.stdout.strip().split()
        print(f"Local commits ahead of remote: {right}")
        print(f"Remote commits ahead of local: {left}")
    else:
        print("Could not compute ahead/behind.")

    print("------------------------------------------------------------\n")


# ---------------------------------------------------------
# High-level git operations
# ---------------------------------------------------------
def safe_ff_pull(repo_path: Path, branch: str, timeout: int = 60) -> Tuple[bool, str]:
    """Fast-forward only update."""
    try:
        fetch = run_git_cmd(["fetch", "--all"], repo_path, timeout)
        if fetch.returncode != 0:
            return False, f"Fetch failed: {fetch.stderr.strip()[:200]}"
    except subprocess.TimeoutExpired:
        return False, "Fetch timed out."

    try:
        merge = run_git_cmd(["merge", "--ff-only"], repo_path, timeout)

        if merge.returncode == 0:
            output = merge.stdout.strip()
            if "up to date" in output.lower():
                return True, "Already up to date."
            return True, "Successfully fast-forwarded."

        if "Not possible to fast-forward" in merge.stderr:
            return False, "Non-fast-forward update required."

        return False, f"Merge failed: {merge.stderr.strip()[:200]}"

    except subprocess.TimeoutExpired:
        return False, "Merge timed out."
    except Exception as e:
        return False, f"Unexpected merge error: {e}"


def force_reset_to_remote(repo_path: Path, branch: str) -> Tuple[bool, str]:
    """Force overwrite repository with remote version."""
    fetch = run_git_cmd(["fetch", "--all"], repo_path)
    if fetch.returncode != 0:
        return False, f"Fetch failed: {fetch.stderr.strip()[:200]}"

    reset = run_git_cmd(["reset", "--hard", f"origin/{branch}"], repo_path)
    if reset.returncode != 0:
        return False, f"Reset failed: {reset.stderr.strip()[:200]}"

    return True, "Force reset completed. Local repo overwritten with remote."


# ---------------------------------------------------------
# Validate Git repository
# ---------------------------------------------------------
def is_valid_git_repo(path: Path) -> bool:
    if not (path / ".git").is_dir():
        return False
    check = run_git_cmd(["rev-parse", "--is-inside-work-tree"], path)
    return check.returncode == 0 and "true" in check.stdout.lower()


# ---------------------------------------------------------
# Recursively find repos under custom_nodes/
# ---------------------------------------------------------
def find_git_repos_in_custom_nodes(root: Path) -> List[Path]:
    repos = []
    for git_dir in root.rglob(".git"):
        repo = git_dir.parent
        if is_valid_git_repo(repo):
            repos.append(repo)
    return repos


# ---------------------------------------------------------
# Main update function
# ---------------------------------------------------------
def update_custom_nodes(show_diff=False, force_overwrite=False):
    root_dir = Path("custom_nodes").resolve()

    if not root_dir.exists():
        print("ERROR: custom_nodes directory not found.")
        return

    print(f"--- Scanning for Git repositories under: {root_dir} ---")

    repos = find_git_repos_in_custom_nodes(root_dir)

    if not repos:
        print("[SUMMARY] No git-based custom nodes found.")
        return

    success_count = 0
    manual_review: Dict[str, Dict] = {}

    for repo in repos:
        print(f"\n[UPDATING] {repo}")

        branch = get_current_branch(repo) or "main"

        dirty = repo_is_dirty(repo)
        conflicts = repo_has_conflicts(repo)
        conflict_files = list_conflict_files(repo)

        # Optionally show diffs
        if show_diff and (dirty or conflicts):
            show_local_vs_remote_diff(repo, branch)

        # Update logic
        if force_overwrite:
            ok, msg = force_reset_to_remote(repo, branch)
        else:
            if dirty:
                ok, msg = False, "Uncommitted changes detected."
            elif conflicts:
                ok, msg = False, "Repository has merge conflicts."
            else:
                ok, msg = safe_ff_pull(repo, branch)

        # Handle results
        if ok:
            success_count += 1
            print(f"  [SUCCESS] {msg}")
        else:
            print(f"  [FAILED]  {msg}")
            manual_review[repo.as_posix()] = {
                "reason": msg,
                "conflicts": conflict_files,
            }

    # Summary
    print("\n" + "=" * 70)
    print("[SUMMARY]")
    print(f"Total repositories found: {len(repos)}")
    print(f"Successfully updated:     {success_count}")
    print(f"Need manual review:       {len(manual_review)}")
    print("=" * 70)

    # Detailed review list
    if manual_review:
        print("\nRepositories requiring manual review:\n")
        for repo_path, details in manual_review.items():
            print(f"- {repo_path}")
            print(f"    Reason: {details['reason']}")
            if details["conflicts"]:
                print("    Conflicts:")
                for f in details["conflicts"]:
                    print(f"      - {f}")
            print()

    print("==============================================================")


# ---------------------------------------------------------
# CLI Argument Handling
# ---------------------------------------------------------
if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Safely update all ComfyUI custom node git repositories."
    )

    parser.add_argument(
        "--show-diff",
        action="store_true",
        help="Show local vs remote differences."
    )

    parser.add_argument(
        "--force-overwrite",
        action="store_true",
        help="Force overwrite local changes with remote via 'git reset --hard'."
    )

    args = parser.parse_args()

    update_custom_nodes(
        show_diff=args.show_diff,
        force_overwrite=args.force_overwrite
    )

