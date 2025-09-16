#!/bin/bash
# test_grafanamcp_server__zed.sh
# Zed integration tests for Grafana MCP server
echo ".. Running Script: ./${BASH_SOURCE[0]/#$(pwd)\//} $@"
echo "What this will be testing:"
echo "│"
echo "├── ZED Grafana-MCP local server setup/integration. Checks editor is installed, and launches it"
echo "│   └── Launches editor with summary file sample (just to confirm)"
echo "│   └── Launches editor with zed-mcp-grafana loca server setup (*separate* server instance of mcp-grafana install locally in Zed!). Then tells user to use an @..text file to prompt in Zed."
echo "│"
echo "└── done this script."


# Load environment variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../bootstrap_helpers/load_env_first.sh"
source "$SCRIPT_DIR/../../${ENV_GRAFANAMCP_FILENAME}"

# Installs Zed if not already installed:
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"$SCRIPT_DIR/../../installers/editors/zed/install_zed.sh"

# Create a test MCP config or dashboard summary file
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOCAL_GEN_DIR="$SCRIPT_DIR/localgenerated"
[ ! -d "${LOCAL_GEN_DIR}" ] && mkdir -p "$LOCAL_GEN_DIR" && chmod u+w "$LOCAL_GEN_DIR"
ZED_TEST_DASH_FILE="${LOCAL_GEN_DIR}/test_mcp_dashboard_summary.json"

echo "Creating test MCP dashboard summary file at $ZED_TEST_DASH_FILE..."
cat > "$ZED_TEST_DASH_FILE" <<EOF
{
  "grafana_url": "${GRAFANA_URL}",
  "mcp_endpoint": "${GRAFANA_MCP_URL}",
  "tenant": "my-tenant",
  "dashboard": {
    "title": "MCP Metrics Dashboard",
    "url": "${GRAFANA_URL}/d/mcp-metrics-dashboard/mcp-metrics-dashboard?orgId=1"
  },
  "notes": "This dashboard was created via MCP test script. You can use this file to summarize or extend dashboard metadata."
}
EOF
# First a simple test: Launch Zed with the test file
echo "First a simple test: Launching Zed with dashboard summary..."
zed "$ZED_TEST_DASH_FILE" &

# -------------------------------
# ZED AGENT PANEL + LLM-INTEGRATED CLI/CHAT-APP TEST
# -------------------------------
echo ""
echo "Test: Launching Zed with LLM-chat agent and sample query files saved..."
# Temp local dir:
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOCAL_GEN_DIR="$SCRIPT_DIR/localgenerated"
[ ! -d "${LOCAL_GEN_DIR}" ] && mkdir -p "$LOCAL_GEN_DIR" && chmod u+w "$LOCAL_GEN_DIR"

# Create a sample query file you can prompt in the editor's LLM chat window:
# to get last 30 minutes of metrics:
ZED_QUERY_FILE_GET30MIN="${LOCAL_GEN_DIR}/test_zed_gemini_query_get30min.txt"
echo ".. Creating sample Gemini query file at $ZED_QUERY_FILE_GET30MIN..."
cat > "$ZED_QUERY_FILE_GET30MIN" <<EOF
Note: A sample url format is like this: http://localhost:3000/explore?schemaVersion=1&panes=%7B%22qbf%22:%7B%22datasource%22:%22PB78FB031097FA2F6%22,%22queries%22:%5B%7B%22refId%22:%22A%22,%22expr%22:%22exampleMetricA1%22,%22range%22:true,%22instant%22:true,%22datasource%22:%7B%22type%22:%22prometheus%22,%22uid%22:%22PB78FB031097FA2F6%22%7D,%22editorMode%22:%22builder%22,%22legendFormat%22:%22__auto%22,%22useBackend%22:false,%22disableTextWrap%22:false,%22fullMetaSearch%22:false,%22includeNullMetadata%22:true%7D%5D,%22range%22:%7B%22from%22:%22now-1h%22,%22to%22:%22now%22%7D%7D%7D&orgId=1
Query the CPU and memory usage from the last 30 minutes using the 'prometheus' datasource. Visualize the result in Grafana Explore (try to ensure the URL works as needed).
EOF

# Create a sample query file you can prompt in the editor's LLM chat window:
# to get correlations:
ZED_QUERY_FILE_GETCORRELATIONS="${LOCAL_GEN_DIR}/test_zed_gemini_query_getCorrelations.txt"
echo ".. Creating sample Gemini query file at $ZED_QUERY_FILE_GETCORRELATIONS..."
cat > "$ZED_QUERY_FILE_GETCORRELATIONS" <<EOF
Note: A sample url format is like this: http://localhost:3000/explore?schemaVersion=1&panes=%7B%22qbf%22:%7B%22datasource%22:%22PB78FB031097FA2F6%22,%22queries%22:%5B%7B%22refId%22:%22A%22,%22expr%22:%22exampleMetricA1%22,%22range%22:true,%22instant%22:true,%22datasource%22:%7B%22type%22:%22prometheus%22,%22uid%22:%22PB78FB031097FA2F6%22%7D,%22editorMode%22:%22builder%22,%22legendFormat%22:%22__auto%22,%22useBackend%22:false,%22disableTextWrap%22:false,%22fullMetaSearch%22:false,%22includeNullMetadata%22:true%7D%5D,%22range%22:%7B%22from%22:%22now-1h%22,%22to%22:%22now%22%7D%7D%7D&orgId=1
Find correlations CPU, memory, ExampleMetricA1, ExampleMetricA2, during the last 5 minutes.
EOF


# Open Zed:
echo ".. Launching Zed with dashboard summary and query..."
zed "$ZED_TEST_DASH_FILE" "$ZED_QUERY_FILE_GET30MIN" "$ZED_QUERY_FILE_GETCORRELATIONS" &
# Remind user to open Agent panel manually:
echo ".. Note: To run Gemini CLI agent, open Zed's Agent panel (Cmd-?) and click '+' to start a Gemini thread."
echo ".. Then @-mention the query file: @$ZED_QUERY_FILE_GET30MIN, or @$$ZED_QUERY_FILE_GETCORRELATIONS.."