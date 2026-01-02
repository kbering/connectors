FROM python:3.11-slim

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    make \
    git \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy the entire project
COPY . .

# Install Python dependencies
RUN make install

# Create config directory
RUN mkdir -p /app/config

# Set environment variables
ENV PYTHONUNBUFFERED=1

# Run the connector
CMD ["./app/connectors_service/.venv/bin/elastic-ingest", "--config-file", "/app/config/config.yml", "--log-level", "INFO"]
