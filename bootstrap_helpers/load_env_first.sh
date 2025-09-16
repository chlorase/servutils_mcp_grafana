#!/bin/bash
# load_env_first.sh
# Load environment variables from .env file

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load environment variables.
# The '-a' auto exports all vars define in the .env, so they're avail in shell and the process and its subprocesses (the '+a' after disables the auto export)
set -a
source "$SCRIPT_DIR/../.env"
set +a