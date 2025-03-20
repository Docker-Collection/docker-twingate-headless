#!/bin/bash

pid_twingate=0
pid_port_forwarding=0

term_handler() {
  if [ "$pid_twingate" -ne 0 ]; then
    kill -SIGTERM "$pid_twingate"
    wait "$pid_twingate"
  fi

  if [ "$pid_port_forwarding" -ne 0 ]; then
    kill -SIGTERM "$pid_port_forwarding"
    wait "$pid_port_forwarding"
  fi

  exit 143;
}

trap 'kill ${!}; term_handler' TERM

if [ -n "$SERVICE_KEY_PATH" ]; then
    if [ -f "$SERVICE_KEY_PATH" ]; then
        SERVICE_KEY=$(cat "$SERVICE_KEY_PATH")
    else
        echo "ERROR! Service key file '$SERVICE_KEY_PATH' not found, exit..."
        exit 1
    fi
fi

if [ -n "$SERVICE_KEY" ]; then
    echo "$SERVICE_KEY" | twingate setup --headless=-
    echo "Start twingate..."
    twingate start &
    pid_twingate="$!"

    sleep 3s

    TWINGATE_STATUS=$(twingate status)
    if [[ "$TWINGATE_STATUS" != 'online' ]]; then
        echo "Exiting with an error as Twingate is not connected"
        exit 1
    fi
else
    echo "ERROR! No service key found, exit..."
    exit 1
fi

if [ "$ENABLE_PORT_FORWARDING" = true ]; then
  # Start the Port Forwarding program
  ./pf &
  pid_port_forwarding="$!"
fi

while :; do
    tail -f /dev/null & wait ${!}
done
