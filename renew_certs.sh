#!/bin/bash
set -e
CERT_DIR="/etc/letsencrypt/live"
WEBROOT="/var/www/certbot"
echo "🔁 Renewing certificates using webroot..."

# Allow certbot to fail (some domains) without exiting the whole script
certbot renew \
  --webroot --webroot-path "$WEBROOT" \
  --non-interactive || echo "⚠️ Some certs failed to renew, continuing to check for reload..."

if find "$CERT_DIR" -type f -newerct "1 day ago" -name "fullchain.pem" -print -quit 2>/dev/null; then
    echo "✅ Certificates renewed. Reloading Nginx..."
    nginx -s reload
else
    echo "ℹ️ No certificates needed renewal."
fi
