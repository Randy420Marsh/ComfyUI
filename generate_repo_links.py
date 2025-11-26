import os
import subprocess
from pathlib import Path

#Updated Python Custom Node Repo Lister Script 
#(Dark Theme + Alphabetical Sorting by URL)

# Path to ComfyUI root (script should be placed in this folder)
ROOT_DIR = Path(__file__).resolve().parent
CUSTOM_NODES_DIR = ROOT_DIR / "custom_nodes"
OUTPUT_FILE = ROOT_DIR / "CustomNodeRepositories.html"


def get_git_remote_url(repo_path):
    """
    Returns the 'origin' remote URL for a Git repository.
    Returns None if not found.
    """
    try:
        result = subprocess.check_output(
            ["git", "-C", str(repo_path), "remote", "get-url", "origin"],
            stderr=subprocess.STDOUT
        )
        return result.decode().strip()
    except subprocess.CalledProcessError:
        return None


def main():
    repo_entries = []

    if not CUSTOM_NODES_DIR.exists():
        print(f"ERROR: Folder does not exist: {CUSTOM_NODES_DIR}")
        return

    for item in CUSTOM_NODES_DIR.iterdir():
        git_dir = item / ".git"
        if git_dir.is_dir():
            remote_url = get_git_remote_url(item)
            repo_entries.append((item.name, remote_url))

    # Sort alphabetically by URL, but keep None URLs at the bottom
    repo_entries.sort(key=lambda x: (x[1] is None, x[1] or ""))

    # HTML with dark theme styling
    html_lines = [
        "<html>",
        "<head>",
        "<title>Custom Node Git Repositories</title>",
        "<style>",
        """
        body {
            background: rgb(40, 44, 52);
            color: rgb(171, 178, 191);
            font-family: Arial, sans-serif;
            text-shadow: rgba(0, 0, 0, 0.3) 0px 1px 1px;
            padding: 20px;
        }
        h1 {
            color: rgb(198, 212, 239);
        }
        ul {
            list-style-type: none;
            padding-left: 0;
        }
        li {
            margin: 8px 0;
            font-size: 18px;
        }
        a {
            color: rgb(97, 175, 239);
            text-decoration: none;
        }
        a:hover {
            text-decoration: underline;
        }
        .no-remote {
            color: rgb(180, 100, 100);
        }
        """,
        "</style>",
        "</head>",
        "<body>",
        "<h1>Custom Node Git Repositories</h1>",
        "<ul>"
    ]

    for name, url in repo_entries:
        if url:
            html_lines.append(f'<li><a href="{url}" target="_blank">{name}</a></li>')
        else:
            html_lines.append(f'<li class="no-remote">{name} (No remote origin found)</li>')

    html_lines.extend([
        "</ul>",
        "</body>",
        "</html>"
    ])

    OUTPUT_FILE.write_text("\n".join(html_lines), encoding="utf-8")
    print(f"Generated HTML file at: {OUTPUT_FILE}")


if __name__ == "__main__":
    main()

