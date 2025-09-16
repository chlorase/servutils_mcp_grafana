#!/bin/bash
# start_local_ollama_mcp_agent.sh
# Launches or restarts the Ollama MCP Agent container and runs a test prompt.

set -euo pipefail
echo ".. Helper: ./${BASH_SOURCE[0]/#$(pwd)\//} $@"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Load .env to ensure OLLAMA_AGENT_PORT is available
source "$SCRIPT_DIR/../bootstrap_helpers/load_env_first.sh"

MODE=${1:-up}
PORT="${OLLAMA_AGENT_PORT:-5053}"

# Check if port is occupied BEFORE container startup
if [ "$MODE" != "restart" ]; then
  if lsof -i :"$PORT" >/dev/null; then
    pid=$(lsof -t -i:$PORT)
    ps_output=$(ps -p "$pid" -o pid,comm)
    if (echo "$ps_output" | grep -q "com.docker.backend"); then
      # Double check ollama container *is* runnign too:
      if docker ps --format '{{.Names}}' | grep -q "servutils_mcp_ollamaagent_container"; then
        echo "Ollama is already running. Exiting normally."
        exit 0
      fi
    fi
    echo "Port $PORT is already in use by a different process. Consider changing OLLAMA_AGENT_PORT in .env."
    lsof -i :"$PORT"
    exit 1
  fi
fi

# Start service
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../bootstrap_helpers/start_service.sh" "ollamaagent" "servutils_mcp_ollamaagent_container" "${MODE}"

# Double check the port has your local ollama running:
echo "+.. After restart of ollama, checking what is the service running at the desired ollama port $PORT currently:"
lsof -i :"$PORT" -n -P | grep -v COMMAND
echo ".."
pid=$(lsof -t -i:$PORT)
if [ -n "$pid" ]; then
  ps -p "$pid" -o pid,comm
fi
echo ".."




# Double check what's running  with docker:
echo "..docker ps"
docker ps

# Send test prompt
echo "+ Sending test prompt to running container:"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"$SCRIPT_DIR/test_local_ollama_mcp_agent.sh"

echo "MCP Agent container started and test prompt executed."
