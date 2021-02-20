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

# Some programs prefer the username/password as separate options
if [ -n "$BITCOIND_AUTH" ]; then
  IFS=':' read BITCOIND_AUTH_USER BITCOIND_AUTH_PASS <<< "$BITCOIND_AUTH"
  export BITCOIND_AUTH_USER BITCOIND_AUTH_PASS
fi

# Set the default BITCOIND_URL
if [ -z "$BITCOIND_URL" ]; then
  # Use host.docker.internal as the default remote bitcoind URL if it resolves (the host's IP address).
  # Requires running with `docker start --add-host host.docker.internal:host-gateway`
  if [ $BITCOIND_MODE == "remote" ] && getent hosts host.docker.internal > /dev/null; then
    export BITCOIND_URL=http://host.docker.internal:$BITCOIND_RPC_PORT/
    host_ip=$(getent hosts host.docker.internal | cut -d' ' -f1)
    net_range=$(cut -d'.' -f1-3 <<< $host_ip).0/24
    info bitcoind "Docker virtual network detected, connecting to host at host.docker.internal ($host_ip)"
    info bitcoind "You will need to configure your node with 'rpcbind=$host_ip' and 'rpcallowip=$net_range'," \
                  "and loosen your firewall (if any) with e.g. 'ufw allow from $net_range to any port $BITCOIND_RPC_PORT'"

  # Use the local bitcoind running inside the container, or possibly on the host if `--net host` was used
  else
    export BITCOIND_URL=http://127.0.0.1:$BITCOIND_RPC_PORT/
  fi
fi
