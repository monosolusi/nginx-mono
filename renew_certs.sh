#!/bin/bash
set -e
CERT_DIR="/etc/letsencrypt/live"
WEBROOT="/var/www/certbot"
echo "🔁 Renewing certificates..."

# Tanpa flag authenticator: tiap cert pakai method yang tersimpan di
# /etc/letsencrypt/renewal/*.conf (webroot untuk publik, dns-digitalocean
# untuk domain internal). Flag --webroot di sini akan menimpa itu.
# Allow certbot to fail (some domains) without exiting the whole script
certbot renew --non-interactive \
  || echo "⚠️ Some certs failed to renew, continuing to check for reload..."

if find "$CERT_DIR" -type f -newerct "1 day ago" -name "fullchain.pem" -print -quit 2>/dev/null; then
    echo "✅ Certificates renewed. Reloading Nginx..."
    nginx -s reload
else
    echo "ℹ️ No certificates needed renewal."
fi
