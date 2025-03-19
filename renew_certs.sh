#!/bin/bash
set -e

CERT_DIR="/etc/letsencrypt/live"
NGINX_CONFIG="/etc/nginx/conf.d/reverse-proxy.conf"

# Attempt to renew certificates
certbot renew --non-interactive --agree-tos --email frans@monosolusi.com || {
    echo "ERROR: Certbot renewal failed. Check logs and Let's Encrypt rate limits."
    exit 1
}

# Check if any certificates were renewed (Certbot returns 0 even if no renewal happened)
if find "$CERT_DIR" -type f -newerct "1 day ago" -name "fullchain.pem" -print -quit 2>/dev/null; then
    echo "Certificates renewed. Reloading Nginx..."
    nginx -s reload
else
    echo "No certificates needed renewal."
fi