#!/bin/bash
# Starts Grafana, Prometheus, Loki, Promtail, example metrics outputter, MCP servers.
# ensures Grafana admin password, creates example dashboard, and opens browser.

set -euo pipefail

#TODO IMPLEMENT