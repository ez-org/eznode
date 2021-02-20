#!/bin/bash
set -xeo pipefail

wget -qO /tmp/bitcoin.tar.gz https://bitcoincore.org/bin/bitcoin-core-$BITCOIND_VERSION/bitcoin-$BITCOIND_VERSION-$BITCOIND_ARCH.tar.gz --show-progress --progress=bar:force
echo "$BITCOIND_SHA256  /tmp/bitcoin.tar.gz" | sha256sum -c -

tar xzf /tmp/bitcoin.tar.gz -C /tmp
mv /tmp/bitcoin-$BITCOIND_VERSION/bin/bitcoin{d,-cli} /usr/local/bin/

# Try to use the same uid/gid as the user might be using on the host
groupadd --gid 1000 bitcoin
useradd --uid 1000 --gid 1000 bitcoin

# Wrap bitcoin-cli to automatically set -datadir and -chain
mv bitcoin-cli /ez/bin/

# Show warning message on shutdown
mv shutdown-message.sh /etc/cont-finish.d/bitcoind-shutdown-message.sh

# Symlink wallet directories to mark them for backup
ln -s /data/bitcoin/wallets /important/bitcoind-wallets
for n in signet testnet3 regtest; do
  ln -s /data/bitcoin/$n/wallets /important/bitcoind-wallets-$n
done

# Required for the fastsync script
apt-get install -qqy --no-install-recommends unzip pv
