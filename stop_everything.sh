#!/bin/bash
# Stops and removes all Docker containers associated with this project (servutils_mcp_grafana*),
# optionally removes volumes, and cleans up the network.

set -euo pipefail

# Load environment variables
./bootstrap_helpers/load_env_first.sh

# -----------------------------
# Stop and remove Docker containers
# -----------------------------
echo "Stopping and removing all servutils containers..."
docker ps -a --format '{{.Names}}' | grep '^servutils_mcp_grafana' | xargs -r docker rm -f || true

# -----------------------------
# Optionally remove volumes (uncomment if full reset desired)
# -----------------------------
# echo "Removing all servutils volumes..."
# docker volume ls -q | grep 'servutils_mcp_grafana' | xargs -r docker volume rm || true

# -----------------------------
# Remove project network
# -----------------------------
echo "Removing project network..."
docker network ls --format '{{.Name}}' | grep '^servutils_mcp_grafana' | xargs -r docker network rm || true

echo "All servutils_mcp_grafana containers and network removed."
