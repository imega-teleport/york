#!/bin/sh

/usr/sbin/nginx -p /data -c /nginx.conf
/usr/bin/rsync --no-detach --daemon --config /etc/rsyncd.conf &

inotifywait -mr -e close_write --fromfile /app/wait-list.txt | while read DEST EVENT FILE
do
    UUID=`echo $(basename "$DEST")`
    if [ "dump.sql" = "$FILE" ]; then
        PASS=$(echo `(printf "get auth:$UUID\r\n"; sleep 0.3) | nc teleport_data 6379` | awk '{print $2}')
        DATA=$(echo `(printf "get user:$UUID\r\n"; sleep 0.3) | nc teleport_data 6379` | awk '{print $2}')
        SITE=$(echo $DATA | jq '.url' | sed 's/\"//g')
        FILES=$(find * -type f -print)
        URL="a.imega.ru"
        JSON=`echo $FILES | jq -R 'split(" ")| {url:env.URL,files: .}'`
        echo "curl -X POST -u $UUID:$PASS --data='$URLS' $SITE?mode=accept-file" >/proc/1/fd/1
    fi
done
