#!/usr/bin/env python3
# Ollama based ACP/MCP Agent, routes to an Ollama server running.
# Can be used directly or integrated with Zed/VScode via settings.json:
# "agent_servers": {
#   "ollama_mistral": {
#     "command": "python",
#     "args": ["/path/to/ollama_mcp_agent.py"],
#     "env": {
#       "OLLAMA_API_URL": "http://localhost:11434"
#     }
#   }
# }

import sys
import json
import os
import requests

LOG_PATH = "/tmp/ollama_agent_debug.log"

def log(msg):
    with open(LOG_PATH, "a") as f:
        f.write(msg + "\n")

def read_stdin():
    for line in sys.stdin:
        yield line.strip()

def send_to_ollama(prompt, model="mistral", api_url="http://localhost:11434"):
    payload = {
        "model": model,
        "prompt": prompt,
        "stream": False
    }
    try:
        response = requests.post(f"{api_url}/api/generate", json=payload)
        response.raise_for_status()
        return response.json().get("response", "(no response)")
    except Exception as e:
        log(f"Error contacting Ollama: {e}")
        return f"(error: {str(e)})"

def main():
    # Resolve API URL from args, env, or fallback
    api_url = sys.argv[1] if len(sys.argv) > 1 else os.getenv("OLLAMA_API_URL")
    if not api_url:
        api_url = "http://localhost:11434"
        log("WARNING: No OLLAMA_API_URL provided. Defaulting to http://localhost:11434")

    log("Starting Ollama ACP Agent...")
    log(f"Using OLLAMA_API_URL = {api_url}")

    for line in read_stdin():
        try:
            req = json.loads(line)
            prompt_text = req.get("prompt", {}).get("text", "")
            reply_text = send_to_ollama(prompt_text, api_url=api_url)

            reply = {
                "response": {
                    "text": reply_text
                }
            }
            print(json.dumps(reply), flush=True)
        except Exception as e:
            error_msg = f"Failed to process input: {e}"
            log(error_msg)
            print(json.dumps({"error": error_msg}), flush=True)

if __name__ == "__main__":
    main()
