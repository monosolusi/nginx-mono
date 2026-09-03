#!/bin/bash
set -e

CERT_DIR="/etc/letsencrypt/live"
WEBROOT="/var/www/certbot"
EMAIL="frans@monosolusi.com"
DOMAINS=(
  "loonas.id"
  "dev.loonas.id"
  "api.loonas.id"
  "app.loonas.id"
  "kibana.loonas.id"
  "ingest-2anwz.loonas.id"
  "uat-api.loonas.id"
  "uat-app.loonas.id"
  "uat.loonas.id"
  "dev-api.loonas.id"
  "dev-app.loonas.id"
  "dev-metabase.loonas.id"
  "dev.monosolusi.com"
  "monosolusi.com"
  "registry.monosolusi.com"
  "activate.monosolusi.com"
)

# Domain yang DNS-nya tidak reachable dari internet (mis. IP Tailscale).
# HTTP-01 mustahil, jadi divalidasi lewat DNS-01 DigitalOcean.
DNS_DOMAINS=(
  "licensing.internal.monosolusi.com"
)

DO_CREDENTIALS="/etc/letsencrypt/digitalocean.ini"

mkdir -p $WEBROOT

# Tulis credential DigitalOcean dari env kalau belum ada (dipakai juga saat renew)
if [ -n "$DO_API_TOKEN" ]; then
  printf 'dns_digitalocean_token = %s\n' "$DO_API_TOKEN" > "$DO_CREDENTIALS"
  chmod 600 "$DO_CREDENTIALS"
fi

# 🔧 1. Generate dummy cert jika belum ada
for domain in "${DOMAINS[@]}" "${DNS_DOMAINS[@]}"; do
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

# 🔐 4b. Domain internal: validasi lewat DNS-01 DigitalOcean
for domain in "${DNS_DOMAINS[@]}"; do
  if [ ! -f "$CERT_DIR/$domain/DUMMY" ]; then
    echo "Certificate for $domain already valid, skipping."
    continue
  fi

  if [ ! -f "$DO_CREDENTIALS" ]; then
    echo "⚠️ $DO_CREDENTIALS tidak ada (set DO_API_TOKEN), skip $domain"
    continue
  fi

  echo "Requesting real certificate for $domain via DNS-01..."
  rm -rf "$CERT_DIR/$domain"
  rm -rf "/etc/letsencrypt/archive/$domain"
  rm -f "/etc/letsencrypt/renewal/$domain.conf"

  certbot certonly --dns-digitalocean \
      --dns-digitalocean-credentials "$DO_CREDENTIALS" \
      --dns-digitalocean-propagation-seconds 60 \
      -d "$domain" \
      --non-interactive \
      --agree-tos \
      --email "$EMAIL" && echo "✅ Certificate issued for $domain"
done


# 🔁 5. Reload nginx untuk gunakan cert baru
echo "Reloading Nginx with real certificates..."
nginx -s reload

# 🌀 6. Keep container alive
tail -f /dev/null
