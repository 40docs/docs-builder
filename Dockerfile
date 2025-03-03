FROM ghcr.io/nginxinc/nginx-unprivileged:latest
#USER root
#RUN apt-get update && apt-get install -y --no-install-recommends apache2-utils && rm -rf /var/lib/apt/lists/*
#USER 101
COPY site /www/
