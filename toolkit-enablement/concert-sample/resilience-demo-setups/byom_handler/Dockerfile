# IBM Confidential
# PID: 5900-BD6, 5900-BBE
# Copyright IBM Corp. 2024

FROM registry.access.redhat.com/ubi8/ubi:latest

# Set working directory
WORKDIR /app

# Install Python 3.11
RUN dnf install -y python3.11 && \
    python3 -m ensurepip --upgrade && \
    python3 -m pip install -U pip

# Copy requirements first for better caching
COPY requirements.txt .

# Install dependencies
RUN python3 -m pip install --no-cache-dir -r requirements.txt

# Copy application files
COPY src/ ./src/
COPY config.yaml .

# Create directory for SSL certificates
# Certificates will be mounted at runtime via volume
RUN mkdir -p /app/certs

# Expose the port (8082 for both HTTP and HTTPS)
EXPOSE 8082

# Run the application
CMD ["python3", "-m", "src.main"]