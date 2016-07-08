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
        #FILES=$(find $DEST* -type f -print | sed 's|/data||g')
        URL="a.imega.club"
        #JSON=`echo $FILES | jq -Rc --arg url "$URL" 'split(" ")| {url:$url,files: .}'`
        FILES=$(find $DEST* -type f -print0 | xargs -0 md5sum | awk '{print $2":"$1}')
        JSON=`echo $FILES | jq -Rc --arg url "$URL" 'split(" ") | {url:$url,files:[ .[]|split(":")|{(.[0]) : .[1]} ]}'`
        curl -s -X POST -u $UUID:$PASS --data '$JSON' $SITE?mode=accept-file
        echo -e `date`"\tteleport_manager: user $UUID send data='$JSON' to $SITE?mode=accept-file" >/proc/1/fd/1
    fi
done
