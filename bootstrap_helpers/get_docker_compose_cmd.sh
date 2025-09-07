#!/bin/bash
# Common helper to determine the Determine Docker Compose command to use (depending on what version installed locally)
set -euo pipefail

if command -v docker-compose >/dev/null 2>&1; then
    COMPOSE_CMD="docker-compose"
elif docker compose version >/dev/null 2>&1; then
    COMPOSE_CMD="docker compose"
else
    echo "Neither docker-compose nor docker compose is available."
    exit 1
fi
export COMPOSE_CMD