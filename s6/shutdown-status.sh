#!/bin/bash
set -eo pipefail
source /ez/util.sh

# Display the list of services that we're waiting for to finish shutting down

is_shutting_down() { [ "$(svstat $s up,wantedup)" = "true false" ]; }
sp='\|/-' spi=1
cd /var/run/s6/services

(
  # Dont display the "waiting for" message if the services shuts down quickly
  sleep 0.3

  while :; do
    services=$(for s in *; do is_shutting_down $s && echo $s || true; done)
    [ -n "$services" ] || break
    echo -ne '\033[K'
    info -n shutdown sent SIGINT, waiting for: $services ${sp:spi++%${#sp}:1} $(echo -ne '\r')
    sleep 0.2
  done
  echo -ne '\033[K'
  info shutdown sent SIGINT, all services are down.
) &
