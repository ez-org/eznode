#!/bin/bash
source /ez/util.sh

if pgrep -x bitcoind > /dev/null; then
    warn bitcoind Please allow some time for Bitcoin Core to sync to disk and shut down cleanly.
fi
