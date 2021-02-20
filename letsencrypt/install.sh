#!/bin/bash
set -xeo pipefail

apt-get install -qqy --no-install-recommends python3-certbot-nginx
mkdir -p /var/log/letsencrypt /var/lib/letsencrypt
