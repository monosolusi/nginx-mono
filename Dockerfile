FROM nginx:latest

RUN apt-get update && apt-get install -y cron

RUN apt-get update && \
    apt-get install -y certbot python3-certbot-nginx

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

COPY reverse-proxy.conf /etc/nginx/conf.d/

EXPOSE 80 443

ENTRYPOINT ["/entrypoint.sh"]