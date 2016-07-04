#!/bin/sh

/usr/sbin/nginx -g daemon off; -p /data -c /nginx.conf &
/usr/bin/rsync --no-detach --daemon --config /etc/rsyncd.conf &

inotifywait -mr -e close_write --fromfile /app/wait-list.txt | while read DEST EVENT FILE
do
    UUID=`echo $(basename "$DEST")`
    if [ "dump.sql" = "$FILE" ]; then
        PASS=$(echo `(printf "get login:$UUID\r\n"; sleep 0.3) | nc teleport_data 6379` | awk '{print $2}')
        SITE=$(echo `(printf "get qwe\r\n"; sleep 0.3) | nc teleport_data 6379` | awk '{print $2}')
        echo curl -u $UUID:$PASS $SITE
    fi
done
