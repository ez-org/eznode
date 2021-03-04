# -- expected to be `source`ed

bool_opt() { [ -n "$1" ] && [ "$1" != "0" ] && [ "$1" != "false" ] && [ "$1" != "off" ]; }

wait_for_file() { # (path, timeout=15s)
  timeout=${2:-15s}
  debug $(basename $PWD) waiting for $1 for up to $timeout
  [ -f "$1" ] \
  || (pfile=$(mktemp) && pidfile $pfile timeout $timeout \
    inotifywait -e create,moved_to --format '%f' -m "$(dirname "$1")" 2>&1 \
    | { grep -qx 'Watches established.' && [ -f "$1" ] || grep -qFx "$(basename "$1")" && killpidf $pfile; }) \
  || { warn $(basename $PWD) $1 did not appear && return 1; }
}

# Utility wrappers for s6 supervision management
svstat() { s6-svstat -o $2 /run/s6/services/$1 2> /dev/null || echo unsupervised; }
svwait() { s6-svwait "${@:2}" /run/s6/services/$1 2> /dev/null; }

wait_for_service() { # (service, timeout=3 minutes)
  timeout=${2:-180000}
  debug $(basename $PWD) waiting for $1 $([ $timeout -ne 0 ] && echo "for up to $(awk '{print ($1/1000)}' <<< $timeout )s")
  svwait $1 -t $timeout -U || { debug $(basename $PWD) failed waiting for $1 && return 1; }
}

wait_for_bitcoind() {
  dir=/run/s6/services/bitcoind
  if [ -d $dir ] && [ ! -f $dir/down ]; then
    # Wait for up to 15 minutes. bitcoind may occasionally take a long time to load up.
    # it could take even longer, but the waiting service will restart and try again when this timeout is reached.
    wait_for_service bitcoind 900000
  fi
}

abort_service() {
  # expected to be called from `run` scripts, with the service directory as the PWD
  debug $(basename $PWD) service is disabled
  touch down && s6-svc -O . && exit 0
}

# Signal that the service is ready through s6's fd notification mechanism
# See https://skarnet.org/software/s6/notifywhenup.html
signal_readiness() { echo >&5; }

# Start a program and keep its pid to a file
pidfile() { #(pidfile, command...)
  "${@:2}" &
  echo $! > $1
  wait
}
killpidf() { #(pidfile)
  kill $(cat "$1") 2> /dev/null || true
  rm "$1"
}

# Helper function to run some code just once (mkdir will fail on subsequent calls)
do_once() { mkdir /tmp/once.$1 2> /dev/null; }

BOLD=$(echo -en '\e[1m')
RED=$(echo -en '\e[31m')
GREEN=$(echo -en '\e[32m')
#LGREEN=$(echo -en '\e[92m')
YELLOW=$(echo -en '\e[33m')
#LYELLOW=$(echo -en '\e[93m')
ORANGE=$(echo -en '\e[0;33m')
BLUE=$(echo -en '\e[34m')
CYAN=$(echo -en '\e[36m')
#LCYAN=$(echo -en '\e[96m')
LGRAY=$(echo -en '\e[0;37m')
RESTORE=$(echo -en '\e[0m')

error() {
  echo >&2 " ${RED}${BOLD}ERROR${RESTORE} ${BOLD}${1}${RESTORE} > ${@:2}"
  exit 1
}
warn() {
  echo >&2 " ${YELLOW}${BOLD}WARN${RESTORE}  ${BOLD}${1}${RESTORE} > ${@:2}"
}
info() {
  if [ "$1" == "-n" ]; then local n="$1"; shift; fi
  echo >&2 $n " ${GREEN}INFO${RESTORE}  ${BOLD}${1}${RESTORE} > ${@:2}"
}
debug() {
  ! bool_opt "$VERBOSE" || \
  echo >&2 $n " ${BLUE}DEBUG${RESTORE} ${BOLD}${1}${RESTORE} > ${@:2}"
}
log_prefix() {
  exec sed "s/^/ ${BOLD}$1${RESTORE} > /"
}
