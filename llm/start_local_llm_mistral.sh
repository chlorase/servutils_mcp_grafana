# start_local_llm_mistral.sh
set -euo pipefail
echo ".. Helper: ./${BASH_SOURCE[0]/#$(pwd)\//} $@"

# Ensure installed
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../bootstrap_helpers/ensure_installers_helpers_synced.sh"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../installers/set_installers_defines_first.sh"
source "${INSTALLERS_DIR}/llm-mcp/install_all_typical_mcp_with_mistral.sh"


# Run Ollama mistral LLM server locally
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../installers/llm/run_mistral_ollama_server.sh"
