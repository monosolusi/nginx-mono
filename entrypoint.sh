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
  "ingest-2anwz.loonas.id"
  "uat-api.loonas.id"
  "uat-app.loonas.id"
  "uat.loonas.id"
  "dev-api.loonas.id"
  "dev-app.loonas.id"
  "dev-metabase.loonas.id"
)

mkdir -p $WEBROOT

# 🔧 1. Generate dummy cert jika belum ada
for domain in "${DOMAINS[@]}"; do
  if [ ! -f "$CERT_DIR/$domain/fullchain.pem" ]; then
    echo "Generating dummy certificate for $domain..."
    mkdir -p $CERT_DIR/$domain
    openssl req -x509 -nodes -newkey rsa:2048 \
      -keyout $CERT_DIR/$domain/privkey.pem \
      -out $CERT_DIR/$domain/fullchain.pem \
      -days 1 \
      -subj "/CN=dummy-cert"
    touch "$CERT_DIR/$domain/DUMMY"
  fi
done

# 🔃 2. Start nginx dengan dummy certs
echo "Starting Nginx with dummy certs..."
nginx

# ⏳ 3. Tunggu nginx siap
sleep 5

# 🔐 4. Jalankan certbot jika cert masih dummy
for domain in "${DOMAINS[@]}"; do
  if [ -f "$CERT_DIR/$domain/DUMMY" ]; then
    echo "Requesting real certificate for $domain..."

    # Hapus dummy + metadata renewal agar tidak create -0001
    rm -rf "$CERT_DIR/$domain"
    rm -rf "/etc/letsencrypt/archive/$domain"
    rm -f "/etc/letsencrypt/renewal/$domain.conf"

    certbot certonly --webroot -w $WEBROOT \
        -d "$domain" \
        --non-interactive \
        --agree-tos \
        --email "$EMAIL" && echo "✅ Certificate issued for $domain"
  else
    echo "Certificate for $domain already valid, skipping."
  fi
done


# 🔁 5. Reload nginx untuk gunakan cert baru
echo "Reloading Nginx with real certificates..."
nginx -s reload

# 🌀 6. Keep container alive
tail -f /dev/null
