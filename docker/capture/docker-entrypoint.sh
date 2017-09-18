#! /bin/sh

NODE_NAME=${NODE_NAME:-moloch}
export ELASTICSEARCH_HOST=${ELASTICSEARCH_HOST:-elasticsearch}
export ELASTICSEARCH_PORT=${ELASTICSEARCH_PORT:-9200}
export ELASTICSEARCH_PREFIX=${ELASTICSEARCH_PREFIX:-}

until curl -sS "http://$ELASTICSEARCH_HOST:$ELASTICSEARCH_PORT/_cluster/health?wait_for_status=yellow&timeout=5s" > /dev/null
do
    echo -n "Waiting for $ELASTICSEARCH_HOST:$ELASTICSEARCH_PORT"
    sleep 5
done

/app/bin/confd -onetime -backend env -confdir /app/etc/confd

# Fun things about moloch
# If you run it in capture mode it will by default drop privs to nobody:nogroup
# and write pcaps to the pcap storage directory with those permissions.
# If you run it in pcap import mode it won't do that. Depending on your
# permissions it will either just fail or write into that dir with the wrong
# owner/group. So we have added our own 'import' and 'capture' wrapper commands.

if [ "$1" = 'import' ]; then
    shift
    exec gosu nobody /app/bin/moloch-capture -n $NODE_NAME -c /app/etc/config.ini --copy -r $@
elif [ "$1" = 'init' ]; then
    exec /app/db/db.pl --prefix "$ELASTICSEARCH_PREFIX" $ELASTICSEARCH_HOST:$ELASTICSEARCH_PORT init
elif [ "$1" = 'migrate' ]; then
    exec /app/db/db.pl --prefix "$ELASTICSEARCH_PREFIX" $ELASTICSEARCH_HOST:$ELASTICSEARCH_PORT upgrade
elif [ "$1" = 'capture' ]; then
    shift
    exec /app/bin/moloch-capture -n $NODE_NAME -c /app/etc/config.ini $@
fi

exec "$@"
