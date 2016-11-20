FROM alpine:3.3

EXPOSE 80
EXPOSE 873

RUN echo "@community http://dl-cdn.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories && \
    apk add --update nginx-lua \
        lua5.1-curl \
        lua5.1-cjson \
        rsync \
        inotify-tools \
        jq \
        lua5.1-filesystem \
        lua5.1-inspect \
        lua5.1-md5 \
        lua5.1-redis@community \
        redis && \
    mkdir -p /tmp/nginx/client-body && \
        rm -rf /var/cache/apk/*

VOLUME ["/data"]

COPY conf/rsyncd.conf /etc/rsyncd.conf
COPY app /app
COPY sites-enabled /sites-enabled
COPY nginx.conf /nginx.conf
COPY vendor /vendor

CMD ["/app/daemon.sh"]
