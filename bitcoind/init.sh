# -- expected to be `source`ed

bitcoind_rpc_port() {
  case $1 in
    bitcoin) echo 8332 ;;
    testnet) echo 18332 ;;
    regtest) echo 18443 ;;
    signet) echo 38332 ;;
    *) error bitcoind Unknown network $1
  esac
}

bitcoind_net_dir() {
  case $1 in
    bitcoin) ;;
    testnet) echo /testnet3 ;;
    signet | regtest) echo /$1 ;;
    *) error bitcoind Unknown network $1
  esac
}
export -f bitcoind_net_dir

bitcoind_chain() {
  case $1 in
    bitcoin) echo main;;
    testnet) echo test ;;
    signet | regtest) echo $1 ;;
    *) error bitcoind Unknown network $1
  esac
}

export BITCOIND_CHAIN=$(bitcoind_chain $NETWORK)

# Run a local Bitcoin Core instance if no BITCOIND_URL/BITCOIND_AUTH was provided and /bitcoin was not mounted
export BITCOIND_MODE=$(([ -z "$BITCOIND_URL" ] && [ -z "$BITCOIND_AUTH" ] && [ ! -d /bitcoin ]) && echo local || echo remote)

[ $BITCOIND_MODE == "remote" ] && [ -z "$BITCOIND_AUTH" ] && [ ! -d /bitcoin ] \
  && error bitcoind BITCOIND_URL was specified, but the /bitcoin datadir was not mounted and BITCOIND_AUTH was not set

# Set config options that needs to be visible to other services
export BITCOIND_DIR=$([ $BITCOIND_MODE == "local" ] && echo /data/bitcoin || ([ -d /bitcoin ] && echo /ext_bitcoin))
export BITCOIND_RPC_PORT=$(bitcoind_rpc_port $NETWORK)
[ -n "$BITCOIND_DIR" ] && export BITCOIND_NETDIR=$BITCOIND_DIR$(bitcoind_net_dir $NETWORK)

# Open up the bitcoind rpc for remote access with the given user/pwd
if [ -n "$BITCOIND_RPC_ACCESS" ]; then
  grep -q ':' <<< $BITCOIND_RPC_ACCESS || error bitcoind 'BITCOIND_RPC_ACCESS expected in <username>:<password> format'
  [ -n "$DOCKER_HOST_IP" ] || warn bitcoind "BITCOIND_RPC_ACCESS was enabled, but the host's IP cannot be detected." \
      "Start with '--add-host host.docker.internal:host-gateway' or manually whitelist it with BITCOIND_OPTS='-rpcallowip=<ip>'."
  export BITCOIND_AUTH=$BITCOIND_RPC_ACCESS
fi

# Some programs prefer the username/password as separate options
if [ -n "$BITCOIND_AUTH" ]; then
  IFS=':' read BITCOIND_AUTH_USER BITCOIND_AUTH_PASS <<< "$BITCOIND_AUTH"
  export BITCOIND_AUTH_USER BITCOIND_AUTH_PASS
fi

# Set the default BITCOIND_URL
if [ -z "$BITCOIND_URL" ]; then
  # Use the host's IP address (if available) as the default remote bitcoind URL.
  # Requires running with `docker start --add-host host.docker.internal:host-gateway`
  if [ $BITCOIND_MODE == "remote" ] && [ -n "$DOCKER_HOST_IP" ]; then
    export BITCOIND_URL=http://host.docker.internal:$BITCOIND_RPC_PORT/
    net_range=$(cut -d'.' -f1-3 <<< $DOCKER_HOST_IP).0/24
    info bitcoind "Docker virtual network detected, connecting to host at host.docker.internal ($DOCKER_HOST_IP)"
    info bitcoind "You will need to configure your node with 'rpcbind=$DOCKER_HOST_IP' and 'rpcallowip=$net_range'," \
                  "and loosen your firewall (if any) with e.g. 'ufw allow from $net_range to any port $BITCOIND_RPC_PORT'"

  # Use the local bitcoind running inside the container, or possibly on the host if `--net host` was used
  else
    export BITCOIND_URL=http://127.0.0.1:$BITCOIND_RPC_PORT/
  fi
fi
