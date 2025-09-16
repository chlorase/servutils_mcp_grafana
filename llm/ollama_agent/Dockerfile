# llm/ollama_agent/Dockerfile
FROM python:3.11-slim

WORKDIR /app

# Create a virtualenv
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"
ENV PIP_DISABLE_PIP_VERSION_CHECK=1

# Install dependencies
RUN pip install --no-cache-dir flask requests
# Add curl for in-container testing/debugging
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

# Copy the application code
COPY ollama_agent.py .

# Run the agent when the container starts
CMD ["python", "ollama_agent.py"]
