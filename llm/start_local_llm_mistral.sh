#!/bin/bash
# start_local_llm_mistral.sh
# Starts the local Mistral LLM server with MCP integration
set -euo pipefail
echo ".. Helper: ./${BASH_SOURCE[0]/#$(pwd)\//} $@"

MODE=${1:-up}  # default 'up', can also pass 'restart'

# -------------------------------
# Ensure installers submodule is synced
# -------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALLERS_SYNC_SCRIPT="${SCRIPT_DIR}/../bootstrap_helpers/ensure_installers_helpers_synced.sh"
source "${INSTALLERS_SYNC_SCRIPT}"

# -------------------------------
# Load installer defines
# -------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALLERS_DEFINES_SCRIPT="${SCRIPT_DIR}/../installers/set_installers_defines_first.sh"
source "${INSTALLERS_DEFINES_SCRIPT}"

# -------------------------------
# Ensure Installed MCP + Mistral stack
# -------------------------------
INSTALL_MCP_SCRIPT="${INSTALLERS_DIR}/llm-mcp/install_all_typical_mcp_with_mistral.sh"
source "${INSTALL_MCP_SCRIPT}"

# -------------------------------
# Start Ollama Mistral LLM server
# -------------------------------
RUN_MISTRAL_SCRIPT="${INSTALLERS_DIR}/llm/run_mistral_ollama_server.sh"
echo "+ source ${RUN_MISTRAL_SCRIPT} ${MODE}"
source "${RUN_MISTRAL_SCRIPT}" "${MODE}"
