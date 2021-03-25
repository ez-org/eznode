#!/bin/bash
set -xeo pipefail

# Setup user & permissions
useradd -m bwt
adduser bwt bitcoin
mkdir /var/log/bwt && chown nobody /var/log/bwt

# Needed to send real-time notifications to the bwt daemon (https://github.com/bwt-dev/bwt#real-time-indexing)
apt-get install -qqy --no-install-recommends netcat-openbsd

# Install bwt
distname=bwt-$BWT_VERSION-$BWT_ARCH
wget -qO /tmp/bwt.tar.gz https://github.com/bwt-dev/bwt/releases/download/v$BWT_VERSION/$distname.tar.gz
echo "$BWT_SHA256  /tmp/bwt.tar.gz" | sha256sum -c -

tar xzf /tmp/bwt.tar.gz -C /tmp
mv /tmp/$distname/bwt /usr/local/bin

# Install utitilies
mv bin/* /ez/bin/
