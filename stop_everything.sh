#!/bin/bash
# Stops and removes all Docker containers associated with this project,
# optionally removes volumes, and cleans up the network.
# PRE: the prefixes of all your containers in this project, as specified in docker-compose.yml use a same 'servutils_mcp_grafana'.
set -euo pipefail

PROJECT_PREFIX="servutils_mcp_grafana"

# Load environment variables
./bootstrap_helpers/load_env_first.sh

# -----------------------------
# Stop and remove Docker containers
# -----------------------------
echo "Stopping and removing all ${PROJECT_PREFIX} containers..."
docker ps -a --format '{{.Names}}' | grep "^${PROJECT_PREFIX}" | xargs -r docker rm -f || true

# -----------------------------
# Optionally remove volumes (uncomment if full reset desired)
# -----------------------------
# echo "Removing all ${PROJECT_PREFIX} volumes..."
# docker volume ls -q | grep "${PROJECT_PREFIX}"" | xargs -r docker volume rm || true

# -----------------------------
# Remove project network
# -----------------------------
echo "Removing project network..."
docker network ls --format '{{.Name}}' | grep "^${PROJECT_PREFIX}" | xargs -r docker network rm || true

echo "All ${PROJECT_PREFIX} containers and network removed."
