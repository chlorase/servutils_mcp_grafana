#!/bin/bash
# ensure_installers_helpers_synced.sh
# Grabs the installers scripts from Git and syncs them if not already present.

set -euo pipefail
echo ".. Helper: ./${BASH_SOURCE[0]/#$(pwd)\//} $@"
echo "Checking for Git submodule: /installers"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALLERS_PATH="${SCRIPT_DIR}/../installers"

if [ ! -d "${INSTALLERS_PATH}/.git" ]; then
  echo "Submodule 'installers' not initialized. Initializing now..."

  echo "+ git submodule init"
  git submodule init

  echo "+ git submodule update"
  git submodule update

  echo "+ git submodule update --remote --merge"
  git submodule update --remote --merge
else
  echo "Submodule 'installers' already initialized."
fi

# Verify the submodule directory exists
if [ ! -d "${INSTALLERS_PATH}" ]; then
  echo "ERROR: Submodule 'installers' directory not found at ${INSTALLERS_PATH}"
  echo "Make sure the submodule is correctly defined in .gitmodules and that you're in the root of the repo."
  exit 1
fi

echo "Submodule 'installers' is synced and available at: ${INSTALLERS_PATH}"
