#! /bin/sh

NODE_NAME=${NODE_NAME:-moloch}
export ELASTICSEARCH_HOST=${ELASTICSEARCH_HOST:-elasticsearch}
export ELASTICSEARCH_PORT=${ELASTICSEARCH_PORT:-9200}

until curl -sS "http://$ELASTICSEARCH_HOST:$ELASTICSEARCH_PORT/_cluster/health?wait_for_status=yellow&timeout=5s" > /dev/null
do
    echo -n "Waiting for $ELASTICSEARCH_HOST:$ELASTICSEARCH_PORT"
    sleep 5
done

confd -onetime -backend env -confdir /app/etc/confd

exec "$@"
