#!/bin/bash
# test_local_ollama_mcp_agent.sh
set -euo pipefail
echo ".. Running test prompt against local Ollama MCP Agent"

TEST_PROMPT='{"prompt": {"text": "Say hello"}}'
PORT="${OLLAMA_AGENT_PORT:-5053}"

echo "+ Sending test prompt to http://localhost:$PORT"
curl -s -X POST "http://localhost:$PORT/generate" \
  -H "Content-Type: application/json" \
  -d "$TEST_PROMPT"
