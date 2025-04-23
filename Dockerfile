FROM ghcr.io/nginxinc/nginx-unprivileged:latest
COPY site /www/
RUN mkdir /www/healthz
RUN echo 'OK' > /www/healthz/index.html
