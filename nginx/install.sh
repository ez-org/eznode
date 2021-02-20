#!/bin/bash
set -xeo pipefail

apt-get install -qqy --no-install-recommends nginx
mkdir /run/nginx && touch /run/nginx/nginx.pid

# Symlink keys/certs directory to mark it for backup
# Includes both self-signed and letsencrypt certificates
ln -s /data/nginx-ssl /important/

# Just so it doesn't show up in the error_log
touch /usr/share/nginx/html/favicon.ico
