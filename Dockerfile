FROM alpine:3.3

EXPOSE 80

RUN apk add --update nginx && \
    mkdir -p /tmp/nginx/client-body && \
        rm -rf /var/cache/apk/*

VOLUME ["/data"]

COPY . /

CMD ["/usr/sbin/nginx", "-g", "daemon off;", "-p", "/data", "-c", "/nginx.conf"]
