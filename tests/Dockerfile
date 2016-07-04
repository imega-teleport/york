FROM alpine:3.3

RUN apk add --update rsync && \
    rm -rf /var/cache/apk/*

VOLUME ["/data"]

WORKDIR /data

