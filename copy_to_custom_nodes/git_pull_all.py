import os
import subprocess
from pathlib import Path
from typing import Tuple

def run_git_pull(repo_path: Path) -> Tuple[bool, str]:
    """
    Executes 'git pull' in the specified repository path.

    Args:
        repo_path: The Path object of the Git repository.

    Returns:
        A tuple (success: bool, message: str)
    """
    print(f"  -> Attempting 'git pull' in {repo_path.name}/...")
    try:
        # Execute 'git pull'. This pulls from the default remote (usually 'origin')
        # and merges into the current branch.
        result = subprocess.run(
            ['git', 'pull'],
            cwd=repo_path,
            capture_output=True,
            text=True,
            check=False,  # Allow non-zero return codes so we can parse errors
            timeout=60    # Allow up to 60 seconds for a pull operation
        )

        # Check for success (return code 0)
        if result.returncode == 0:
            # Success, often containing "Already up to date."
            if "Already up to date." in result.stdout or "up to date" in result.stdout:
                return True, "Already up to date."
            return True, "Successfully pulled changes."
        else:
            # An error occurred. Check stderr for common issues.
            error_output = result.stderr.strip()

            if "not a git command" in error_output or "command not found" in error_output:
                return False, "CRITICAL: 'git' command not found. Ensure Git is installed."

            # Common errors like merge conflicts or uncommitted changes
            if "fatal: refusing to merge" in error_output or "Your local changes to" in error_output or "Automatic merge failed" in error_output:
                 return False, f"Merge conflict or uncommitted local changes detected. Manual intervention required. Output: {error_output[:100]}..."

            # Fallback for other errors
            return False, f"Git pull failed (Code: {result.returncode}). Error: {error_output[:200]}..."

    except FileNotFoundError:
        return False, "CRITICAL: 'git' command not found. Ensure Git is installed and in your system PATH."
    except subprocess.TimeoutExpired:
        return False, "WARNING: Git command timed out."
    except Exception as e:
        return False, f"UNEXPECTED ERROR: {e}"

def pull_all_repos():
    """
    Scans the current directory for subdirectories that are Git repositories
    and executes 'git pull' in each one.
    """
    current_dir = Path.cwd()
    print(f"--- Starting 'git pull' across all repositories in: {current_dir} ---")

    found_repos_count = 0
    pulled_successfully_count = 0

    # Iterate over all entries in the current directory
    for item in current_dir.iterdir():
        if item.is_dir():
            # Check if it contains a .git directory
            if (item / '.git').is_dir():
                found_repos_count += 1

                print(f"\n[REPO CHECKING] {item.name}/")

                success, message = run_git_pull(item)

                if success:
                    pulled_successfully_count += 1
                    print(f"  [STATUS] SUCCESS: {message}")
                else:
                    print(f"  [STATUS] FAILED: {message}")


    print("\n" + "="*50)
    if found_repos_count == 0:
        print("[SUMMARY] No Git repositories found in subdirectories.")
    else:
        print(f"[SUMMARY] Pull operation attempted on {found_repos_count} repositories.")
        print(f"          - Successfully completed: {pulled_successfully_count}")
        print(f"          - Failed or needed intervention: {found_repos_count - pulled_successfully_count}")
        print("Note: Failed pulls often require manual git intervention (e.g., resolving conflicts).")
    print("="*50)


if __name__ == "__main__":
    pull_all_repos()
