#!/bin/bash
set -xeo pipefail

apt-get install -qqy --no-install-recommends dropbear-bin xxd xauth

mkdir /var/log/dropbear && chown nobody:nogroup /var/log/dropbear

# `dropbearconvert` is included in `dropbear-bin`, but is not in PATH
# https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=748825
mv /usr/lib/dropbear/dropbearconvert /usr/local/bin

# We don't need an SSH client
rm /usr/bin/dbclient

# Symlink keys directory to mark it for backup
ln -s /data/ssh-keys /important/
