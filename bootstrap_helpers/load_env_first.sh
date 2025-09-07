#!/bin/bash
# Load environment variables from .env file

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load environment variables
set +u
source "$SCRIPT_DIR/../.env"
set -u
