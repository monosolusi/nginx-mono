#!/bin/bash
set -e

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

mkdir -p $WEBROOT

# 🔧 1. Generate dummy cert jika belum ada (agar nginx bisa start)
for domain in "${DOMAINS[@]}"; do
  if [ ! -f "$CERT_DIR/$domain/fullchain.pem" ]; then
    echo "Generating dummy certificate for $domain..."
    mkdir -p $CERT_DIR/$domain
    openssl req -x509 -nodes -newkey rsa:2048 \
      -keyout $CERT_DIR/$domain/privkey.pem \
      -out $CERT_DIR/$domain/fullchain.pem \
      -days 1 \
      -subj "/CN=localhost"
  fi
done

# 🔃 2. Start nginx agar certbot bisa jalan
echo "Starting Nginx with dummy certs..."
nginx

# ⏳ 3. Tunggu nginx siap
sleep 5

# 🔐 4. Ganti dummy cert dengan certbot yang valid
for domain in "${DOMAINS[@]}"; do
  if [ ! -f "$CERT_DIR/$domain/fullchain.pem" ] || openssl x509 -in "$CERT_DIR/$domain/fullchain.pem" -noout -text | grep -q "CN=localhost"; then
    echo "Requesting real certificate for $domain..."
    certbot certonly --webroot -w $WEBROOT \
      -d "$domain" \
      --non-interactive \
      --agree-tos \
      --email "$EMAIL" || {
        echo "❌ ERROR: Certbot failed for $domain"
        exit 1
      }
  else
    echo "Certificate for $domain already exists and valid, skipping."
  fi
done

# 🔁 5. Reload nginx agar pakai cert yang baru
echo "Reloading Nginx with real certificates..."
nginx -s reload

# 🌀 6. Keep container alive
tail -f /dev/null
