FROM nginx:latest

RUN apt-get update && apt-get install -y cron

# Debian trixie tidak punya paket python3-certbot-dns-digitalocean, jadi
# certbot + plugin-nya dipasang lewat venv (harus satu env supaya plugin kebaca).
RUN apt-get update && \
    apt-get install -y python3 python3-venv && \
    python3 -m venv /opt/certbot && \
    /opt/certbot/bin/pip install --no-cache-dir --upgrade pip && \
    /opt/certbot/bin/pip install --no-cache-dir certbot certbot-dns-digitalocean && \
    ln -s /opt/certbot/bin/certbot /usr/bin/certbot && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/www/certbot

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

COPY renew_certs.sh /renew_certs.sh
RUN chmod +x /renew_certs.sh

RUN echo "0 18 * * * root /renew_certs.sh" >> /etc/crontab
RUN crontab /etc/crontab

COPY reverse-proxy.conf /etc/nginx/conf.d/

EXPOSE 80 443

CMD service cron start && /entrypoint.sh