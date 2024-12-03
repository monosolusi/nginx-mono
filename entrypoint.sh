#!/bin/bash

# Domains to secure
domains=(
  "sancaka-api.monosolusi.com"
)

# Join domains into a comma-separated string
domain_list=$(IFS=,; echo "${domains[*]}")

# Issue the certificate (replace with your preferred method)
acme.sh --issue -d $domain_list --standalone

# Install the certificate
acme.sh --install-cert -d $domain_list \
    --fullchain-file /etc/ssl/certs/fullchain.pem \
    --key-file /etc/ssl/private/key.pem \
    --reloadcmd "nginx -s reload"

# Start nginx
nginx -g 'daemon off;'