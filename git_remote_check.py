import os
import subprocess
from pathlib import Path
from typing import Dict, List, Optional, Tuple

def get_git_remotes(repo_path: Path) -> Optional[Dict[str, Tuple[str, str]]]:
    """
    Executes 'git remote -v' in the specified repository path and parses the output.

    Args:
        repo_path: The Path object of the Git repository.

    Returns:
        A dictionary mapping remote names to (fetch_url, push_url), or None if an error occurs.
    """
    try:
        # Use subprocess.run to execute the command in the target directory
        result = subprocess.run(
            ['git', 'remote', '-v'],
            cwd=repo_path,
            capture_output=True,
            text=True,
            check=True,  # Raise an exception if the command returns a non-zero exit code
            timeout=10
        )
    except subprocess.CalledProcessError as e:
        # This usually means 'git remote -v' failed (e.g., no remotes configured)
        print(f"  [ERROR] Git command failed in '{repo_path.name}': {e.stderr.strip()}")
        return None
    except FileNotFoundError:
        # This means the 'git' command itself could not be found
        print("  [CRITICAL ERROR] 'git' command not found. Ensure Git is installed and in your system PATH.")
        return None
    except subprocess.TimeoutExpired:
        print(f"  [WARNING] Git command timed out in '{repo_path.name}'.")
        return None
    except Exception as e:
        print(f"  [UNEXPECTED ERROR] in '{repo_path.name}': {e}")
        return None

    # Parse the output
    remotes: Dict[str, Tuple[str, str]] = {}
    lines = result.stdout.strip().split('\n')
    
    # Git remote -v output looks like:
    # origin  https://github.com/user/repo.git (fetch)
    # origin  https://github.com/user/repo.git (push)
    for line in lines:
        parts = line.split()
        if len(parts) == 3:
            name, url, type_ = parts
            url = url.strip()
            type_ = type_.strip('()')
            
            if name not in remotes:
                # Initialize with empty strings for push/fetch
                remotes[name] = ('', '')
            
            fetch_url, push_url = remotes[name]
            
            if type_ == 'fetch':
                remotes[name] = (url, push_url)
            elif type_ == 'push':
                remotes[name] = (fetch_url, url)
                
    return remotes

def check_subdirectories_for_git():
    """
    Scans the current directory for subdirectories that are Git repositories
    and reports their remote URLs.
    """
    print(f"--- Scanning subdirectories in: {Path.cwd()} ---")
    
    # Get all items in the current directory
    current_dir = Path.cwd()
    found_repos = 0
    
    # Iterate over all entries in the current directory
    for item in current_dir.iterdir():
        if item.is_dir():
            # Check if it contains a .git directory (the marker of a Git repository)
            if (item / '.git').is_dir():
                found_repos += 1
                print(f"\n[FOUND REPO] {item.name}/")
                
                remotes = get_git_remotes(item)
                
                if remotes:
                    for name, (fetch_url, push_url) in remotes.items():
                        print(f"  Remote: {name}")
                        print(f"    Fetch (Pull): {fetch_url if fetch_url else '[Not Set]'}")
                        print(f"    Push (Send):  {push_url if push_url else '[Not Set]'}")
                else:
                    # This case is handled by the error logging inside get_git_remotes
                    if found_repos == 1:
                        print("  No remotes configured or an error occurred.")


    if found_repos == 0:
        print("\n[INFO] No Git repositories found in subdirectories.")
    else:
        print(f"\n--- Scan Complete: Found {found_repos} repositories ---")


if __name__ == "__main__":
    check_subdirectories_for_git()
