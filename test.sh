#!/bin/bash
set -eo pipefail
shopt -s expand_aliases

: ${DOCKER_IMAGE:=${1:-eznode}}

alias ez='docker exec eztest'
xpub=tpubD6NzVbkrYhZ4X9SErApTtvF833DCUydyjhVyWiciPXmqC6pzngB6EyhUnnqJvhXgJmHj3bkWdcSjkD4FsysLWsAZ1nJNdjV7CJfHBFu66C8
ezdata=$(mktemp -d) && chmod 777 $ezdata

echo Starting up eznode...
docker run -t --rm --name eztest -h eztest \
    -v $ezdata:/data -v /etc/hosts:/ez/hosts $DOCKER_IMAGE \
    NETWORK=regtest XPUB=$xpub VERBOSE=1 HOST_ALIAS=eztest NO_STARTUP_BANNER=1 \
    SPECTER=1 SSL=1 SSHD=1 TOR=1 TOR_CONFIG='SocksPort 0.0.0.0:9050' &

trap 'docker stop eztest' EXIT

echo Waiting for bitcoind/bwt to come up...
sleep 5
ez s6-svwait -U /run/s6/services/{bitcoind,bwt}
echo "$(ez status)"

echo Testing bitcoind and bwt...
addr=$(curl -fsS -L eztest:3060/wallet/ju9npsex/next | jq -er .address)
txid=$(ez bitcoin-cli -rpcwallet=miner sendtoaddress $addr 1.234)
sleep 3
[ $(curl -fsS eztest:3060/tx/$txid | jq -er .balance_change) -eq 123400000 ]
[ $(curl -fsS eztest:3060/address/$addr/stats | jq -er .unconfirmed_balance) -eq 123400000 ]
echo ok

echo Testing specter...
echo "$(curl -fsS eztest:25441/about)" | grep -q '<img src="/static/img/checkbox-tick.svg" width="30px">'
# checkbox-tick indicates a successful connection to bitcoin core
echo ok

echo Testing btc-rpc-explorer...
echo "$(curl -fsS eztest:3002/explorer/node-details)" | grep -q '<span class="text-success">Synchronized</span>'
echo ok

echo Testing SSH...
ssh-keygen -f ~/.ssh/known_hosts -R "[eztest]:2222" &> /dev/null || true
docker cp eztest:/data/ssh-keys/client_ecdsa $ezdata/ssh-key
ssh -i $ezdata/ssh-key -o 'StrictHostKeyChecking no' \
    -fTN -L 127.0.0.1:3061:eztest:3060 -p 2222 root@eztest
curl -fsS -m 2 localhost:3061/tx/$txid > /dev/null
echo ok

echo Testing SSL...
curl -fsS -m 2 -k https://eztest:3443/bwt/tx/$txid > /dev/null
echo ok

echo Testing Tor...
onion=$(ez cat /data/tor-hsv/hostname)
curl -fsS -m 60 -x socks5h://eztest:9050 http://$onion:3060/tx/$txid > /dev/null
echo ok

echo All tests ok!