#!/bin/bash
set -xeo pipefail

# inotify-tools needed to wait for the tor onion hostname file to appear
apt-get install -qqy --no-install-recommends tor inotify-tools

# Symlink onion service directory to mark it for backup
ln -s /data/tor-hsv /important/
