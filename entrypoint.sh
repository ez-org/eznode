#!/bin/bash
set -eo pipefail
source /ez/util.sh

# s6-overlay options. https://github.com/just-containers/s6-overlay#customizing-s6-behaviour
export S6_KEEP_ENV=1
export S6_SERVICES_GRACETIME=2700000 # 45 minutes, to allow Bitcoin Core to shutdown cleanly
export S6_KILL_FINISH_MAXTIME=$S6_SERVICES_GRACETIME # for the shutdown-status script

# Detect host OS
export HOST_OS=$(uname -r | grep -Eq -- '-(moby|linuxkit)' && echo macOS \
      || (uname -r | grep -Eq -- '-microsoft' && echo Windows \
      || echo Linux))

# Check if the docker container is running with a TTY
[ -t 1 ] && export IS_TTY=1

# Installation wizard
if [ "$1" == wizard ]; then
  /ez/wizard/wizard
  shift
fi

# Load config options from file
# `set -a` exports all defined variables without requiring an explicit `export`
if [ -f /data/config ]; then set -a; source /data/config; set +a
else touch /data/config; fi
# Prevent services from making modifications -- this gets run as (the container's) root
chmod 600 /data/config

# Allow specifying KEY=VAL environment variables as CLI arguments
while grep -q '^[A-Z][A-Z0-9_]\+=' <<< "$1"; do
  IFS='=' read key val <<< "$1"
  export $key="$val"
  shift
done

# If dashed arguments were given with no preceding program name, treat them as parameters for bwt
#if [[ "$1" == "-"* ]]; then
#  export BWT_OPTS="$BWT_OPTS $@"
#  set -- # clear $@
#fi

# We don't currently expect any other arguments
[ -n "$1" ] && error init "Unexpected arguments: $@"

# Run some sanity checks
installed() { [ -d /etc/services.d/$1 ]; }
bool_opt "$BWT" && ! installed bwt && error init BWT is enabled but not installed
bool_opt "$SPECTER" && ! installed specter && error init SPECTER is enabled but not installed
bool_opt "$EXPLORER" && ! installed btc-rpc-explorer && error init EXPLORER requires btc-rpc-explorer to be installed
bool_opt "$TOR" && ! installed tor && error init TOR is enabled but not installed
bool_opt "$SSHD" && ! installed dropbear && error init SSHD requires dropbear to be installed
bool_opt "$SSL" && ! installed nginx && error init SSL requires nginx to be installed
mountpoint -q /data || [ "$NETWORK" == "regtest" ] || bool_opt "$THROWAWAY" \
   || error init 'Data directory not mounted. Run with `-v /path/on/host:/data` to mount it, or set THROWAWAY=1 to start anyway.'$'\n'\
                 'This would mean that no data will get persisted, including the bitcoind data files, SSH keys, SSL keys/certs and Tor onion service keys.'

# Cleanup leftover temporary files from previous runs
rm -rf /tmp/*

# Detect networking mode, determine the address to bind on and automatically set /ez/hosts
source /ez/networking.sh

# Give services an opportunity to run early sanity checks and export variables
# that'll be visible to other services across the container.
source <(cat /etc/services.d/*/init)

# Keep env vars to filesystem to make them available for `docker exec` commands and SSH sessions
mkdir -p /var/run/s6 && s6-dumpenv /var/run/s6/container_environment

# Display config options
bool_opt "$VERBOSE" && env | grep -v '^\(HOSTNAME\|PWD\|HOME\|TERM\|SHLVL\|PATH\|_\|S6_.*\|BASH_FUNC_.*\)=\|^[ }]\|^$' \
  | while read c; do debug config $c; done

# Hand control over to the s6 init stage 1
exec /init s6-pause
# s6-pause is needed to properly handle ^C in interactive docker run shell
