#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------------------------
# uv-update-nodes_v3.sh
#
# - Parses an HTML file containing repository links (e.g. CustomNodeRepositories.html)
# - Clones missing repos into custom_nodes/ (shallow by default)
# - Scans custom_nodes/ recursively for requirements.txt (including local-only nodes) and installs via:
#       uv pip install -r requirements.txt
# - Optionally installs editable packages from node roots that contain setup.py and/or pyproject.toml
# - Runs uv pip check and prints conflicts (if any)
# -----------------------------------------------------------------------------

usage() {
  cat <<'EOF'
Usage:
  ./uv-update-nodes_v3.sh [options]

Options:
  --html PATH                 HTML file to parse for repo URLs.
                              Default: ./CustomNodeRepositories.html
  --custom-nodes PATH         custom_nodes directory path.
                              Default: ./custom_nodes
  --depth N                   git clone depth for new clones (shallow).
                              Default: 1
  --update-existing           If repo folder already exists, run 'git pull' inside it.
                              Default: off (skip existing).
  --recurse-submodules        Clone with --recurse-submodules for new clones.
                              Default: off
  --jobs N                    Parallel clone jobs (best effort). Default: 1
  --install-setup-py          For node roots containing setup.py, run: uv pip install -e .
                              Default: off
  --install-pyproject         For node roots containing pyproject.toml, run: uv pip install -e .
                              Default: off
  --python VERSION            uv python pin VERSION (e.g., 3.12). Default: 3.12
  --venv PATH                 Virtualenv directory. Default: ./.venv
  --dry-run                   Print planned actions without cloning/installing.
  -h, --help                  Show this help.

Examples:
  ./uv-update-nodes_v3.sh
  ./uv-update-nodes_v3.sh --html ./CustomNodeRepositories.html --update-existing
  ./uv-update-nodes_v3.sh --install-pyproject --install-setup-py
EOF
}

# Defaults
HTML_FILE="./CustomNodeRepositories.html"
CUSTOM_NODES_DIR="./custom_nodes"
DEPTH="1"
UPDATE_EXISTING="0"
RECURSE_SUBMODULES="0"
JOBS="1"
INSTALL_SETUP_PY="0"
INSTALL_PYPROJECT="0"
PYTHON_VERSION="3.12"
VENV_DIR="./.venv"
DRY_RUN="0"

log() { printf '%s\n' "$*"; }
warn() { printf '%s\n' "$*" >&2; }
die() { warn "ERROR: $*"; exit 2; }

# Parse args
while [[ $# -gt 0 ]]; do
  case "$1" in
    --html) HTML_FILE="${2:-}"; shift 2 ;;
    --custom-nodes) CUSTOM_NODES_DIR="${2:-}"; shift 2 ;;
    --depth) DEPTH="${2:-}"; shift 2 ;;
    --update-existing) UPDATE_EXISTING="1"; shift ;;
    --recurse-submodules) RECURSE_SUBMODULES="1"; shift ;;
    --jobs) JOBS="${2:-}"; shift 2 ;;
    --install-setup-py) INSTALL_SETUP_PY="1"; shift ;;
    --install-pyproject) INSTALL_PYPROJECT="1"; shift ;;
    --python) PYTHON_VERSION="${2:-}"; shift 2 ;;
    --venv) VENV_DIR="${2:-}"; shift 2 ;;
    --dry-run) DRY_RUN="1"; shift ;;
    -h|--help) usage; exit 0 ;;
    *) die "Unknown option: $1" ;;
  esac
done

COMFY_UI_DIR="$(pwd -P)"
HTML_FILE="${HTML_FILE/#\~/$HOME}"
CUSTOM_NODES_DIR="${CUSTOM_NODES_DIR/#\~/$HOME}"
VENV_DIR="${VENV_DIR/#\~/$HOME}"

log "COMFY_UI_DIR       = ${COMFY_UI_DIR}"
log "HTML_FILE          = ${HTML_FILE}"
log "CUSTOM_NODES_DIR   = ${CUSTOM_NODES_DIR}"
log "VENV_DIR           = ${VENV_DIR}"
log "DEPTH              = ${DEPTH}"
log "UPDATE_EXISTING    = ${UPDATE_EXISTING}"
log "RECURSE_SUBMODULES = ${RECURSE_SUBMODULES}"
log "JOBS               = ${JOBS}"
log "INSTALL_SETUP_PY   = ${INSTALL_SETUP_PY}"
log "INSTALL_PYPROJECT  = ${INSTALL_PYPROJECT}"
log "DRY_RUN            = ${DRY_RUN}"
log

[[ -f "${HTML_FILE}" ]] || die "HTML file not found: ${HTML_FILE}"

command -v uv >/dev/null 2>&1 || die "'uv' not found on PATH. Install uv and re-run."
command -v git >/dev/null 2>&1 || die "'git' not found on PATH. Install Git and re-run."

# -----------------------------------------------------------------------------
# Venv bootstrapping
# -----------------------------------------------------------------------------
if [[ "${DRY_RUN}" == "0" ]]; then
  uv python pin "${PYTHON_VERSION}"

  if [[ -d "${VENV_DIR}" ]]; then
    # shellcheck disable=SC1090
    source "${VENV_DIR}/bin/activate"
  else
    uv venv --python "${PYTHON_VERSION}" "${VENV_DIR}"
    # shellcheck disable=SC1090
    source "${VENV_DIR}/bin/activate"
  fi

  python --version
  uv pip install --upgrade pip
else
  log "[DRY-RUN] Would pin python ${PYTHON_VERSION} and create/activate venv at ${VENV_DIR}"
fi

mkdir -p "${CUSTOM_NODES_DIR}"

# -----------------------------------------------------------------------------
# Extract repo URLs from HTML
# -----------------------------------------------------------------------------
extract_repos() {
  python - "$1" <<'PY'
import re, sys
from html.parser import HTMLParser
from urllib.parse import urlparse

html_path = sys.argv[1]
text = open(html_path, "r", encoding="utf-8", errors="ignore").read()

class P(HTMLParser):
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

p = P()
p.feed(text)

# Also pick up any raw URLs in text
for m in re.findall(r'https?://[^\s"<>]+', text):
    p.urls.add(m)

def norm(u: str) -> str:
    u = u.strip()
    u = re.sub(r'[),.]+$', '', u)
    pr = urlparse(u)
    # drop query/fragment
    pr = pr._replace(query="", fragment="")
    return pr.geturl()

urls = [norm(u) for u in p.urls if re.match(r"^https?://", u.strip(), re.I)]

out = []
seen = set()

for u in sorted(urls):
    if u in seen:
        continue
    seen.add(u)

    pr = urlparse(u)
    host = (pr.netloc or "").lower()
    path = pr.path or ""

    # Accept explicit .git URLs as-is
    if u.endswith(".git"):
        out.append(u)
        continue

    # Heuristic for GitHub repo links: /owner/repo(/...)
    if "github.com" in host:
        seg = [s for s in path.split("/") if s]
        if len(seg) >= 2:
            repo_url = pr._replace(path=f"/{seg[0]}/{seg[1]}", query="", fragment="").geturl()
            out.append(repo_url)
            continue

    # Generic heuristic: if URL path looks like /owner/repo, keep first two segments
    seg = [s for s in path.split("/") if s]
    if len(seg) >= 2:
        repo_url = pr._replace(path=f"/{seg[0]}/{seg[1]}", query="", fragment="").geturl()
        out.append(repo_url)

# Deduplicate while preserving order
final = []
seen = set()
for u in out:
    if u not in seen:
        seen.add(u)
        final.append(u)

print("\n".join(final))
PY
}

log "Parsing repositories from HTML..."
REPO_LIST="$(extract_repos "${HTML_FILE}")"
if [[ -z "${REPO_LIST}" ]]; then
  die "No repository URLs found in ${HTML_FILE}"
fi

REPO_COUNT="$(printf '%s\n' "${REPO_LIST}" | sed '/^\s*$/d' | wc -l | tr -d ' ')"
log "Found ${REPO_COUNT} repository URL(s)."
log

# -----------------------------------------------------------------------------
# Clone/update repos
# -----------------------------------------------------------------------------
clone_one() {
  local repo_url="$1"
  local repo_name
  repo_name="$(basename "${repo_url}")"
  repo_name="${repo_name%.git}"

  local dest="${CUSTOM_NODES_DIR}/${repo_name}"

  if [[ -d "${dest}" ]]; then
    if [[ "${UPDATE_EXISTING}" == "1" ]]; then
      if [[ "${DRY_RUN}" == "1" ]]; then
        log "[DRY-RUN] Would update existing repo: ${repo_name} (git pull)"
      else
        log "Updating ${repo_name}..."
        ( cd "${dest}" && git pull --ff-only ) || {
          warn "[WARN] git pull failed for ${repo_name}; continuing."
        }
      fi
    else
      log "[SKIP] ${repo_name} (already exists)"
    fi
    return 0
  fi

  if [[ "${DRY_RUN}" == "1" ]]; then
    if [[ "${RECURSE_SUBMODULES}" == "1" ]]; then
      log "[DRY-RUN] Would clone: git clone --depth ${DEPTH} --recurse-submodules ${repo_url} ${dest}"
    else
      log "[DRY-RUN] Would clone: git clone --depth ${DEPTH} ${repo_url} ${dest}"
    fi
    return 0
  fi

  log "Cloning ${repo_name}..."
  if [[ "${RECURSE_SUBMODULES}" == "1" ]]; then
    git clone --depth "${DEPTH}" --recurse-submodules "${repo_url}" "${dest}"
  else
    git clone --depth "${DEPTH}" "${repo_url}" "${dest}"
  fi
}

# Parallel cloning (best-effort) using xargs -P where available
if [[ "${JOBS}" -gt 1 ]]; then
  log "Cloning with up to ${JOBS} parallel job(s)..."
  if command -v xargs >/dev/null 2>&1; then
    export CUSTOM_NODES_DIR DEPTH UPDATE_EXISTING RECURSE_SUBMODULES DRY_RUN
    export -f clone_one log warn
    printf '%s\n' "${REPO_LIST}" | sed '/^\s*$/d' | xargs -n 1 -P "${JOBS}" -I {} bash -c 'clone_one "$@"' _ {}
  else
    warn "[WARN] xargs not found; falling back to sequential cloning."
    while IFS= read -r repo; do
      [[ -z "${repo}" ]] && continue
      clone_one "${repo}"
    done <<< "${REPO_LIST}"
  fi
else
  while IFS= read -r repo; do
    [[ -z "${repo}" ]] && continue
    clone_one "${repo}"
  done <<< "${REPO_LIST}"
fi

log
log "Repository clone/update phase complete."
log

# -----------------------------------------------------------------------------
# Install requirements.txt (including local-only nodes)
# -----------------------------------------------------------------------------
install_requirements() {
  log "Scanning for requirements.txt under: ${CUSTOM_NODES_DIR}"

  # shellcheck disable=SC2207
  local req_files=($(find "${CUSTOM_NODES_DIR}" \
    -type f -name "requirements.txt" \
    -not -path "*/.git/*" \
    -not -path "*/.venv/*" \
    -not -path "*/venv/*" \
    -not -path "*/__pycache__/*" \
    -print | sort -u))

  if [[ "${#req_files[@]}" -eq 0 ]]; then
    log "No requirements.txt files found."
    return 0
  fi

  log "Found ${#req_files[@]} requirements.txt file(s). Installing with: uv pip install -r"
  local failures=()

  for req in "${req_files[@]}"; do
    log
    log "Installing requirements: ${req}"
    if [[ "${DRY_RUN}" == "1" ]]; then
      log "[DRY-RUN] Would run: (cd \"$(dirname "${req}")\" && uv pip install -r \"$(basename "${req}")\")"
      continue
    fi

    if ! ( cd "$(dirname "${req}")" && uv pip install -r "$(basename "${req}")" ); then
      warn "[WARN] Failed installing: ${req}"
      failures+=("${req}")
    fi
  done

  if [[ "${#failures[@]}" -gt 0 ]]; then
    warn
    warn "One or more requirements installs failed (${#failures[@]}):"
    for f in "${failures[@]}"; do
      warn "  - ${f}"
    done
    warn "Continuing."
  fi
}

install_requirements
log

# -----------------------------------------------------------------------------
# Optional editable installs for setup.py / pyproject.toml at node roots
# -----------------------------------------------------------------------------
install_editables() {
  local node_root
  local installed_any="0"

  shopt -s nullglob
  for node_root in "${CUSTOM_NODES_DIR}"/*/ ; do
    [[ -d "${node_root}" ]] || continue

    local has_setup="0"
    local has_pyproject="0"
    [[ -f "${node_root}/setup.py" ]] && has_setup="1"
    [[ -f "${node_root}/pyproject.toml" ]] && has_pyproject="1"

    if [[ "${INSTALL_PYPROJECT}" == "1" && "${has_pyproject}" == "1" ]]; then
      installed_any="1"
      log
      log "Installing editable (pyproject.toml): ${node_root}"
      if [[ "${DRY_RUN}" == "1" ]]; then
        log "[DRY-RUN] Would run: (cd \"${node_root}\" && uv pip install -e .)"
      else
        ( cd "${node_root}" && uv pip install -e . ) || warn "[WARN] Editable install failed (pyproject): ${node_root}"
      fi
      continue
    fi

    if [[ "${INSTALL_SETUP_PY}" == "1" && "${has_setup}" == "1" ]]; then
      installed_any="1"
      log
      log "Installing editable (setup.py): ${node_root}"
      if [[ "${DRY_RUN}" == "1" ]]; then
        log "[DRY-RUN] Would run: (cd \"${node_root}\" && uv pip install -e .)"
      else
        ( cd "${node_root}" && uv pip install -e . ) || warn "[WARN] Editable install failed (setup.py): ${node_root}"
      fi
    fi
  done
  shopt -u nullglob

  if [[ "${installed_any}" == "0" ]]; then
    log "No editable installs performed (either flags disabled or no matching node roots found)."
  fi
}

if [[ "${INSTALL_SETUP_PY}" == "1" || "${INSTALL_PYPROJECT}" == "1" ]]; then
  log "Optional editable install phase..."
  install_editables
  log
fi

# -----------------------------------------------------------------------------
# Dependency conflict report
# -----------------------------------------------------------------------------
log "Running: uv pip check"
if [[ "${DRY_RUN}" == "1" ]]; then
  log "[DRY-RUN] Would run: uv pip check"
  exit 0
fi

if ! uv pip check; then
  warn
  warn "Dependency conflicts were detected by 'uv pip check' (see output above)."
  warn "If you paste the output here, I can propose a concrete resolution plan (pins/overrides/constraints)."
else
  log "No dependency conflicts reported by 'uv pip check'."
fi

log
log "Done."
