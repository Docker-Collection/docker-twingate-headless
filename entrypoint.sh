#!/bin/bash

pid=0

term_handler() {
  if [ "$pid" -ne 0 ]; then
    kill -SIGTERM "$pid"
    wait "$pid"
  fi
  exit 143;
}

trap 'kill ${!}; term_handler' TERM

if [ ! -z "$SERVICE_KEY" ]; then
    echo "$SERVICE_KEY" | twingate setup --headless=-
    echo "Start twingate..."
    twingate start &
    pid="$!"

    sleep 3s

    TWINGATE_STATUS=$(twingate status)
    if [[ "$TWINGATE_STATUS" != 'online' ]]; then
        echo "Exiting with error as Twingate is not connected"
        exit 1
    fi
else
    echo "ERROR! No service key found, exit..."
    exit 1
fi

while :; do
    tail -f /dev/null & wait ${!}
done