FROM python:3.11-slim

WORKDIR /app

# Create a virtualenv
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"
RUN pip install --no-cache-dir flask prometheus_client
ENV PIP_DISABLE_PIP_VERSION_CHECK=1

# Copy requirements file
COPY requirements.txt .

# Install dependencies in virtualenv
RUN pip install --no-cache-dir -r requirements.txt

# Copy the application code
COPY example_metrics_emitter.py .

# Install any dependencies (Flask is needed for the HTTP server)
RUN pip install flask
RUN pip install --no-cache-dir --no-warn-script-location flask prometheus_client

# Run the script when the container starts
CMD ["python", "example_metrics_emitter.py"]