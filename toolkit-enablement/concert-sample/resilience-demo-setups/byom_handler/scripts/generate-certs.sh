#!/bin/bash
# IBM Confidential
# PID: 5900-BD6, 5900-BBE
# Copyright IBM Corp. 2024

# Script to generate self-signed SSL certificates for BYOM Handler
# For production use, replace with CA-signed certificates

set -e

echo "Generating self-signed SSL certificates for BYOM Handler..."
echo ""

# Create certs directory if it doesn't exist
mkdir -p certs

# Check if certificates already exist
if [ -f "certs/cert.pem" ] && [ -f "certs/key.pem" ]; then
    echo "WARNING: Certificates already exist in certs/ directory"
    read -p "Do you want to overwrite them? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Certificate generation cancelled."
        exit 0
    fi
fi

# Get hostname (default to localhost)
read -p "Enter hostname (default: localhost): " HOSTNAME
HOSTNAME=${HOSTNAME:-localhost}

# Get validity period (default to 365 days)
read -p "Enter certificate validity in days (default: 365): " DAYS
DAYS=${DAYS:-365}

echo ""
echo "Generating certificates with the following parameters:"
echo "  Hostname: $HOSTNAME"
echo "  Validity: $DAYS days"
echo ""

# Create a temporary config file for SAN
cat > certs/openssl.cnf << EOF
[req]
default_bits = 4096
prompt = no
default_md = sha256
distinguished_name = dn
req_extensions = v3_req

[dn]
C=US
ST=State
L=City
O=IBM
OU=Concert
CN=$HOSTNAME

[v3_req]
subjectAltName = @alt_names

[alt_names]
DNS.1 = $HOSTNAME
DNS.2 = localhost
IP.1 = 127.0.0.1
EOF

# Generate private key and certificate with SAN
openssl req -x509 -newkey rsa:4096 -nodes \
  -keyout certs/key.pem \
  -out certs/cert.pem \
  -days $DAYS \
  -config certs/openssl.cnf \
  -extensions v3_req \
  2>/dev/null

# Remove temporary config file
rm -f certs/openssl.cnf

# Set appropriate permissions
chmod 644 certs/cert.pem
chmod 600 certs/key.pem

echo ""
echo "✓ Certificates generated successfully!"
echo ""
echo "Certificate files:"
echo "  Certificate: certs/cert.pem"
echo "  Private Key: certs/key.pem"
echo ""
echo "Certificate details:"
openssl x509 -in certs/cert.pem -noout -subject -dates -ext subjectAltName
echo ""
echo "IMPORTANT NOTES:"
echo "  1. These are self-signed certificates for testing/development only"
echo "  2. For production, use CA-signed certificates"
echo "  3. When testing with curl, use -k flag to skip certificate verification:"
echo "     curl -k https://localhost:8082/health"
echo "  4. Never commit these certificates to version control"
echo ""
echo "Next steps:"
echo "  1. Ensure ssl_enabled: true in config.yaml"
echo "  2. Run ./build-run.sh to start the handler with HTTPS"
echo ""

