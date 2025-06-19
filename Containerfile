FROM registry.access.redhat.com/ubi9/nginx-124:latest

USER 0

RUN dnf install -y nginx-mod-http-perl perl-JSON-PP \
    && dnf clean all

# Create directories and set permissions
RUN mkdir -p /usr/share/nginx/html/static/release \
    && mkdir -p /run \
    && mkdir -p /etc/nginx/certs \
    && mkdir -p /var/log/nginx \
    && mkdir -p /var/lib/nginx/tmp/client_body \
    && chmod 770 /var/log/nginx \
    && chmod -R 750 /var/lib/nginx

COPY identity.pl /etc/nginx/perl/identity.pl

RUN chown -R nginx:nginx /usr/share/nginx/html /etc/nginx/certs /var/log/nginx /etc/nginx /var/lib/nginx /run

COPY nginx/ /etc/nginx/

USER nginx

CMD ["nginx", "-g", "daemon off;"]
