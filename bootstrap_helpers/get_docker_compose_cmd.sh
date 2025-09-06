#!/bin/bash

# Common helper to determine the right cmd line name for docker compose (depending on which version installed)
if command -v docker-compose >/dev/null 2>&1; then
  echo "docker-compose"
elif docker compose version >/dev/null 2>&1; then
  echo "docker compose"
else
  echo "Neither docker-compose nor docker compose is available."
  exit 1
fi