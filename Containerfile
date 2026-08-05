FROM registry.access.redhat.com/ubi10/nginx-126:latest

USER 0

RUN dnf install -y nginx-mod-http-perl perl-JSON-PP \
    && dnf clean all

# Create directories and set permissions (omit /var/log/nginx so nginx cannot create default error.log)
RUN mkdir -p /usr/share/nginx/html/static/release \
    && mkdir -p /run \
    && mkdir -p /etc/nginx/certs \
    && mkdir -p /var/lib/nginx/tmp/client_body \
    && chmod -R 750 /var/lib/nginx

COPY identity.pl /etc/nginx/perl/identity.pl

RUN chown -R nginx:nginx /usr/share/nginx/html /etc/nginx/certs /etc/nginx /var/lib/nginx /run

COPY nginx/ /etc/nginx/

USER nginx

EXPOSE 8443/tcp

CMD ["nginx", "-g", "daemon off; error_log /dev/stderr info;"]
