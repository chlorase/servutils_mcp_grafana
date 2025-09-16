#!/bin/bash
# test_grafanamcp_server.sh
# Test the Grafana MCP server

echo "-------"
echo ""
echo "Running Script: ./${BASH_SOURCE[0]/#$(pwd)\//} $@"
echo "Starting TESTS"
echo "What we will be testing: "
echo "│"
echo "├── Creates dashboard summary JSON for hooking up to MCP agents"
echo "│   └── Used for metadata viewing (not dashboard creation)"
echo "│"
echo "├── Calls create_example_dashboard_for_grafanamcp.sh"
echo "│   └── Generates metrics, builds dashboard, uploads via API"
echo "│"
echo "├── Opens dashboard in browser, just to confirm its there"
echo "│"
echo "├── Verifies dashboard exists via curl + token"
echo "|-- TEST our Custom Grafana-MCP server is up."
echo "│"
echo "├── Editor LLM MCP-Grafana integration tests (info to follow).."
echo "│"
echo "└── END"


# Load environment variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../bootstrap_helpers/load_env_first.sh"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../${ENV_GRAFANAMCP_FILENAME}"

echo "# -------------------------------"
echo "# Setup dashboard first in grafana (no MCP specific testing yet)"
echo "# -------------------------------"
echo "Pre-tests Grafana Dashboard/Metrics Setup.."
echo ""
# Create dashboard:
echo "..Creating MCP metrics dashboard..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"$SCRIPT_DIR/../../example_metrics_emitter/create_example_dashboard_for_grafanamcp.sh"

# Open dashboard in browser
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../example_metrics_emitter/open_example_dashboard_for_grafanamcp.sh"
echo ".. Running curl test to fetch dashboard metadata..."
DASHBOARD_UID="mcp-metrics-dashboard"
CURL_CMD="curl -H \"Authorization: Bearer ${GRAFANA_SERVICE_ACCOUNT_TOKEN}\" \"${GRAFANA_URL}/api/dashboards/uid/${DASHBOARD_UID}\""
echo "..Executing: $CURL_CMD"
eval "$CURL_CMD"
echo ""

# -------------------------------
# Custom Grafana-MCP Server tests
# (Test of our Custom Grafana-MCP server without any Chat-UI etc)
# -------------------------------
echo "# -------------------------------"
echo "# Custom Grafana-MCP Server tests"
echo "# -------------------------------"
echo "..Checking if our custom instance of MCP server port 8000 is open..."
( echo > /dev/tcp/localhost/8000 ) &> /dev/null && \
  echo "...Port 8000 is open and accepting connections." || \
  echo "...Port 8000 is closed or MCP server is not listening."

# -------------------------------
# LLM-CHAT/EDITOR INTERFACE, LINKED WITH MCP-GRAFANA, INTEGRATION TESTS
# Note Grafana's stock mcp-grafana doesn't expose regular REST endpoints, so you need to install a client like Zed to interface with the mcp-grafana dashboards and create etc (Zed has LLM and grafana MCP libraries etc you can use later, for dev use)
# -------------------------------
echo "LLM-Chat/Editor Interface integration tests.."

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/test_grafanamcp_server__zed.sh"


echo ""
echo ""
echo ""
echo "Grafana-MCP related tests complete."

