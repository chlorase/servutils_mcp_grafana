#!/usr/bin/env python3
# ollama_agent.py

import os
import requests
from flask import Flask, request, jsonify

app = Flask(__name__)

OLLAMA_API_URL = os.getenv("OLLAMA_API_URL", "http://localhost:11434")
OLLAMA_AGENT_PORT = int(os.getenv("OLLAMA_AGENT_PORT", "5053"))

@app.route("/generate", methods=["POST"])
def generate():
    data = request.json or {}
    prompt = data.get("prompt", {}).get("text", "")
    payload = {
        "model": "mistral",
        "prompt": prompt,
        "stream": False
    }
    try:
        response = requests.post(f"{OLLAMA_API_URL}/api/generate", json=payload)
        response.raise_for_status()
        return jsonify({"response": {"text": response.json().get("response", "(no response)")}})
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route("/health", methods=["GET"])
def health():
    return jsonify({"status": "ok", "target": OLLAMA_API_URL})

if __name__ == "__main__":
    print(f"Starting Ollama MCP Agent on port {OLLAMA_AGENT_PORT}, targeting {OLLAMA_API_URL}")
    app.run(host="0.0.0.0", port=5000) # Keep Flask here on 5000
