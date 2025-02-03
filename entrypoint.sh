#!/bin/bash
set -e  # Exit immediately on error

CERT_DIR="/etc/letsencrypt/live"

check_and_generate_cert() {
    local domain=$1

    # Check if the certificate already exists and is valid
    if [ -f "$CERT_DIR/$domain/fullchain.pem" ]; then
        echo "Certificate for $domain already exists, skipping Certbot request."
    else
        echo "Requesting certificate for $domain..."
        certbot certonly --standalone --dry-run \
          -d "$domain" \
          --non-interactive \
          --agree-tos \
          --email frans@monosolusi.com || {
            echo "ERROR: Certbot failed for $domain. Check logs and Let's Encrypt rate limits."
            exit 1
          }
    fi
}

# Request certificates only if necessary
check_and_generate_cert "grafana.tokosumatra.monosolusi.com"
check_and_generate_cert "loki.tokosumatra.monosolusi.com"

# Update Nginx configuration with existing certificates
sed -i "s|ssl_certificate     /etc/ssl/certs/ssl-cert-snakeoil.pem;|ssl_certificate     $CERT_DIR/grafana.tokosumatra.monosolusi.com/fullchain.pem;|" /etc/nginx/conf.d/reverse-proxy.conf
sed -i "s|ssl_certificate_key /etc/ssl/private/ssl-cert-snakeoil.key;|ssl_certificate_key $CERT_DIR/grafana.tokosumatra.monosolusi.com/privkey.pem;|" /etc/nginx/conf.d/reverse-proxy.conf

sed -i "s|ssl_certificate     /etc/ssl/certs/ssl-cert-snakeoil.pem;|ssl_certificate     $CERT_DIR/loki.tokosumatra.monosolusi.com/fullchain.pem;|" /etc/nginx/conf.d/reverse-proxy.conf
sed -i "s|ssl_certificate_key /etc/ssl/private/ssl-cert-snakeoil.key;|ssl_certificate_key $CERT_DIR/loki.tokosumatra.monosolusi.com/privkey.pem;|" /etc/nginx/conf.d/reverse-proxy.conf

# Ensure all certificates exist before proceeding
if [ ! -f "$CERT_DIR/grafana.tokosumatra.monosolusi.com/fullchain.pem" ] || \
   [ ! -f "$CERT_DIR/loki.tokosumatra.monosolusi.com/fullchain.pem" ]; then
    echo "ERROR: One or more SSL certificates not generated!"
    exit 1
fi

# Start nginx
nginx -g 'daemon off;'