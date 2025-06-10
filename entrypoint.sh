#!/bin/bash
set -e  # Exit immediately on error

CERT_DIR="/etc/letsencrypt/live"
WEBROOT="/var/www/certbot"
EMAIL="frans@monosolusi.com"
DOMAINS=(
  "loonas.id"
  "api.loonas.id"
  "app.loonas.id"
  "api.ninjas.loonas.id"
  "ninjas.loonas.id"
  "kibana.loonas.id"
)

# Ensure webroot directory exists
mkdir -p $WEBROOT

# Start Nginx in background
nginx

# Wait for Nginx to be ready
sleep 5

# Function to check and request certificate via webroot
check_and_generate_cert() {
    local domain=$1

    if [ -f "$CERT_DIR/$domain/fullchain.pem" ]; then
        echo "Certificate for $domain already exists, skipping request."
    else
        echo "Requesting certificate for $domain..."
        certbot certonly --webroot -w $WEBROOT \
            -d "$domain" \
            --non-interactive \
            --agree-tos \
            --email "$EMAIL" || {
                echo "ERROR: Certbot failed for $domain"
                exit 1
            }
    fi
}

# Loop over each domain and ensure cert exists
for domain in "${DOMAINS[@]}"; do
    check_and_generate_cert "$domain"
done

for domain in "${DOMAINS[@]}"; do
    if [ ! -f "$CERT_DIR/$domain/fullchain.pem" ]; then
        echo "ERROR: Missing certificate for $domain"
        exit 1
    fi
done

# Reload nginx to pick up certs
nginx -s reload

# Keep container alive
tail -f /dev/null