#!/bin/sh

/usr/sbin/nginx -p /data -c /nginx.conf
/usr/bin/rsync --no-detach --daemon --config /etc/rsyncd.conf &

inotifywait -mr -e close_write --fromfile /app/wait-list.txt | while read DEST EVENT FILE
do
    UUID=`echo $(basename "$DEST")`

    CUR_QTY=`find $DEST -name '*.sql' | wc -l`
    QTY=`echo $FILE | cut -d '.' -f1 | cut -d '_' -f3`

    if [[ $QTY -eq $CUR_QTY ]]; then

        PASS=$(redis-cli -h teleport_data get "auth:$UUID")
        if [ ! -z "$PASS" -a "$PASS" != " " ]; then
            DATA=$(redis-cli -h teleport_data get "user:$UUID")
            SITE=$(echo $DATA | jq '.url' | sed 's/\"//g')

            if test "$(ls -A "$DEST")"; then
                notify-plugin-files -user "$UUID" -pass "$PASS" -url "$SITE/teleport?mode=accept-file&ver=300" -storageUrl "http://a.imega.club/storage" -path $DEST
            fi
        fi

    fi
done
