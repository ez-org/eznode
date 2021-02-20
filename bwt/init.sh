# -- expected to be `source`ed

# Configure Bitcoin Core to notify BWT whenever there are new blocks or wallet transactions
if bool_opt "$BWT"; then
  echo -e '#!/bin/sh\nnc -q1 -U /run/bwt/notify-socket 2> /dev/null || true' > /ez/bin/notify-bwt
  chmod +x /ez/bin/notify-bwt
  export BITCOIND_OPTS="-blocknotify=notify-bwt -walletnotify=notify-bwt $BITCOIND_OPTS"
fi
