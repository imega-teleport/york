#!/bin/sh

/usr/sbin/nginx -p /data -c /nginx.conf
/usr/bin/rsync --no-detach --daemon --config /etc/rsyncd.conf &

inotifywait -mr -e close_write --fromfile /app/wait-list.txt | while read DEST EVENT FILE
do
    UUID=`echo $(basename "$DEST")`
    PASS=$(redis-cli -h teleport_data get "auth:$UUID")
    if [ ! -z "$PASS" -a "$PASS" != " " ]; then
        DATA=$(redis-cli -h teleport_data get "user:$UUID")
        SITE=$(echo $DATA | jq '.url' | sed 's/\"//g')
        URL="http://a.imega.club"
        URIPATH="storage"
        FILES=$(find $DEST* -type f -print0 | xargs -0 md5sum | sed "s|/data/$UUID||g" | awk '{print $2":"$1}')
        JSON=`echo $FILES | jq -Rc --arg url "$URL" --arg uuid "$UUID" --arg uripath "$URIPATH" 'split(" ") | {url:$url,uuid:$uuid,uripath:$uripath,files:[ .[]|split(":")|{(.[0]) : .[1]} ]}'`
        curl -s -X POST -u $UUID:$PASS --data $JSON $SITE/teleport?mode=accept-file
    fi
done
