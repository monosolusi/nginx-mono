FROM nginx:latest

# Copy your reverse proxy configuration
COPY reverse-proxy.conf /etc/nginx/conf.d/