#!/bin/bash

# Obtain certificates (nginx needs to be running)
certbot certonly --standalone \
  -d sancaka-api.monosolusi.com  \
  --non-interactive \
  --agree-tos \
  --email frans@monosolusi.com

# Configure nginx to use the certificates
sed -i "s/ssl_certificate     /etc/ssl/certs/ssl-cert-snakeoil.pem;/ssl_certificate     /etc/letsencrypt/live/sancaka-api.monosolusi.com/fullchain.pem;/" /etc/nginx/conf.d/reverse-proxy.conf
sed -i "s/ssl_certificate_key /etc/ssl/private/ssl-cert-snakeoil.key;/ssl_certificate_key /etc/letsencrypt/live/sancaka-api.monosolusi.com/privkey.pem;/" /etc/nginx/conf.d/reverse-proxy.conf

sed -i "s/ssl_certificate     /etc/ssl/certs/ssl-cert-snakeoil.pem;/ssl_certificate     /etc/letsencrypt/live/tokosumatra.monosolusi.com/fullchain.pem;/" /etc/nginx/conf.d/reverse-proxy.conf
sed -i "s/ssl_certificate_key /etc/ssl/private/ssl-cert-snakeoil.key;/ssl_certificate_key /etc/letsencrypt/live/tokosumatra.monosolusi.com/privkey.pem;/" /etc/nginx/conf.d/reverse-proxy.conf

# Start nginx
nginx -g 'daemon off;'