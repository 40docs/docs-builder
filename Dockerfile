FROM ghcr.io/nginxinc/nginx-unprivileged:latest
COPY site /www/
USER ROOT
RUN mkdir /www/healthz
RUN echo 'OK' > /www/healthz/index.html
USER 101
