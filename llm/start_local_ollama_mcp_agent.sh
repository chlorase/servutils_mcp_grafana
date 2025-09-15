#!/bin/bash
# start_local_ollama_mcp_agent.sh
# Launches or restarts the Ollama MCP Agent container and runs a test prompt.

set -euo pipefail
echo ".. Helper: ./${BASH_SOURCE[0]/#$(pwd)\//} $@"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../bootstrap_helpers/get_docker_compose_cmd.sh"

# Load .env to ensure OLLAMA_AGENT_PORT is available
set -a
source "$SCRIPT_DIR/../.env"
set +a

MODE="${1:-up}"
CONTAINER_NAME="servutils_mcp_ollamaagent_container"
SERVICE_NAME="ollamaagent"
PORT="${OLLAMA_AGENT_PORT:-5053}"

# Check if port is occupied BEFORE container startup
if lsof -i :"$PORT" >/dev/null; then
  echo "Port $PORT is already in use. Consider changing OLLAMA_AGENT_PORT in .env."
  lsof -i :"$PORT"
  exit 1
fi

# Check if container is running
EXISTING_CONTAINER=$(docker ps -q -f name="^/${CONTAINER_NAME}$")

if [ -n "$EXISTING_CONTAINER" ]; then
  if [ "$MODE" == "restart" ]; then
    echo "-> Container $CONTAINER_NAME is running. Restarting..."
    docker rm -f "$CONTAINER_NAME"

    $COMPOSE_CMD rm -f "$SERVICE_NAME"
    $COMPOSE_CMD build "$SERVICE_NAME"
    $COMPOSE_CMD up -d "$SERVICE_NAME"

    sleep 1
  else
    echo "-> Container $CONTAINER_NAME is already running. Skipping startup."
    exit 0
  fi
else
  echo "+ Starting Docker container for MCP Agent: $SERVICE_NAME"
  $COMPOSE_CMD up -d "$SERVICE_NAME"
fi

echo "+ Waiting for container to initialize..."
sleep 2

echo "+ Sending test prompt to running container: $CONTAINER_NAME"
"$SCRIPT_DIR/test_local_ollama_mcp_agent.sh"

echo "MCP Agent container started and test prompt executed."
