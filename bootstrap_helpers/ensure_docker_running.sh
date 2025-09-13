#!/bin/bash
# Common helper to ensure local docker daemon running
set -euo pipefail
echo "Running $(basename "${BASH_SOURCE[0]}")"

if ! docker info >/dev/null 2>&1; then
    echo "Starting Docker Desktop..."
    case "$OSTYPE" in
      darwin*) open -a Docker ;;
      linux*) systemctl --user start docker.desktop >/dev/null 2>&1 || true ;;
      msys*|cygwin*) echo "Start Docker manually on Windows." ;;
    esac
    while ! docker info >/dev/null 2>&1; do sleep 2; done
fi
echo "Docker is running."