# -- expected to be `source`ed

bool_opt "$BWT" || return 0

# Configure bitcoind to notify bwt whenever there are new blocks or wallet transactions
export BITCOIND_OPTS="-blocknotify=notify-bwt -walletnotify=notify-bwt $BITCOIND_OPTS"

# Configure bitcoind to allow manual pruning via the RPC when BWT is configured with PRUNE_UNTIL
if [ -n "$PRUNE_UNTIL" ]; then
  export PRUNE=${PRUNE:-1}
  [ $PRUNE -eq 1 ] || error bwt Set one of PRUNE or PRUNE_UNTIL, not both
fi
