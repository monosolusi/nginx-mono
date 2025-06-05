FROM nginx:latest

RUN apt-get update && apt-get install -y cron

RUN apt-get update && \
    apt-get install -y certbot python3-certbot-nginx

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