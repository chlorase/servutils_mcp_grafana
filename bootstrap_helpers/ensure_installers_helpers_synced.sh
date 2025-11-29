#!/bin/bash
# ensure_installers_helpers_synced.sh
# Ensures the 'installers' submodule is initialized, updated, and available locally.
# TODO: refactor to use common helper in installers/_helpers/.. instead of this file's duplicating code (see ./installers/_helpers/ensure_helpers_submodules_synced.sh)
set -euo pipefail
echo ".. Helper: ./${BASH_SOURCE[0]/#$(pwd)\//} $@"

echo "Checking for Git submodule: /installers"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
INSTALLERS_PATH="${REPO_ROOT}/installers"
# Ensure we're in a Git repo (path)
if ! git -C "$REPO_ROOT" rev-parse --is-inside-work-tree &> /dev/null; then
  echo "ERROR: Not inside a Git repository. Cannot sync submodules."
  exit 1
fi
# Initialize submodule if not present
if [ ! -d "${INSTALLERS_PATH}/.git" ]; then
  echo "Submodule 'installers' not initialized. Initializing now..."

  echo "+ git submodule init"
  git -C "$REPO_ROOT" submodule init

  echo "+ git submodule update"
  git -C "$REPO_ROOT" submodule update

  echo "+ git submodule update --remote --merge"
  git -C "$REPO_ROOT" submodule update --remote --merge
else
  echo "Submodule 'installers' already initialized."
fi

# Fallback: manually clone if submodule failed
if [ ! -d "${INSTALLERS_PATH}" ]; then
  echo "Submodule directory not found. Attempting manual clone..."
  echo "+ git clone https://github.com/chlorase/installers ${INSTALLERS_PATH}"
  git clone https://github.com/chlorase/installers "${INSTALLERS_PATH}"
fi

# Final check
if [ ! -d "${INSTALLERS_PATH}" ]; then
  echo "ERROR: Submodule 'installers' directory still missing at ${INSTALLERS_PATH}"
  exit 1
fi

echo "Submodule 'installers' is synced and available at: ${INSTALLERS_PATH}"
