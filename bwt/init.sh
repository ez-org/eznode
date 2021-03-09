# -- expected to be `source`ed

# Configure Bitcoin Core to notify BWT whenever there are new blocks or wallet transactions
if bool_opt "$BWT"; then
  export BITCOIND_OPTS="-blocknotify=notify-bwt -walletnotify=notify-bwt $BITCOIND_OPTS"
fi
