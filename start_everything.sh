#!/bin/bash
# Starts Grafana, Prometheus, Loki, Promtail, example metrics outputter, MCP servers.
# ensures Grafana admin password, creates example dashboard, and opens browser. #TODO IMPLEMENT all these
set -euo pipefail

# Start Grafana server
./grafana/start_grafana_server.sh

#TODO IMPLEMENT rest