#!/bin/bash
# IBM Confidential
# PID: 5900-BD6, 5900-BBE
# Copyright IBM Corp. 2024

# Build script for BYOM Handler

set -e

echo "Building BYOM Handler Docker image..."

# Build the Docker image
docker build -t byom-handler:latest .

echo "Build complete!"
echo ""

# Check if certs directory exists
if [ ! -d "certs" ]; then
  echo "WARNING: certs directory not found!"
  echo "For HTTPS support, you need SSL certificates in the certs directory."
  echo "Run './generate-certs.sh' to create self-signed certificates for testing."
  echo ""
fi

# Run the container
docker run -d \
  --name byom-handler \
  -p 8082:8082 \
  --env-file .env \
  -v $(pwd)/config.yaml:/app/config.yaml:ro \
  -v $(pwd)/certs:/app/certs:ro \
  byom-handler:latest

echo ""
echo "Handler started successfully!"

# Check if SSL is enabled in config
if grep -q "ssl_enabled: true" config.yaml; then
  echo "Access at: https://localhost:8082"
  echo ""
  echo "Note: If using self-signed certificates, use -k flag with curl:"
  echo "  curl -k https://localhost:8082/health"
else
  echo "Access at: http://localhost:8082"
  echo ""
  echo "Note: SSL is disabled. To enable HTTPS, set ssl_enabled: true in config.yaml"
fi

echo ""
echo "To view logs:"
echo "  docker logs -f byom-handler"
echo ""
echo "To stop:"
echo "  docker stop byom-handler && docker rm byom-handler"

