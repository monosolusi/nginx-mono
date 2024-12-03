FROM nginx:latest

RUN curl https://get.acme.sh | sh -s email=frans@monosolusi.com

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

COPY reverse-proxy.conf /etc/nginx/conf.d/

EXPOSE 80 443

ENTRYPOINT ["/entrypoint.sh"]