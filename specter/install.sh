#!/bin/bash
set -xeo pipefail
shopt -s extglob

# Setup user & permissions
useradd -m specter
adduser specter bitcoin
mkdir /var/log/specter && chown nobody /var/log/specter
export HOME=/home/specter

# Dependencies (runtime deps on first line, others are build deps)
apt-get install -yqq --no-install-recommends python3.7 libusb-1.0-0 jq \
  python3.7-dev python3-pip python3-setuptools build-essential libudev-dev libusb-1.0-0-dev python3-wheel \
  $([[ $(dpkg --print-architecture) == "arm"* ]] && echo libffi-dev libssl-dev)

# Install Specter
wget -qO /tmp/specterd.tar.gz https://github.com/cryptoadvance/specter-desktop/archive/v$SPECTER_VERSION.tar.gz
echo "$SPECTER_SHA256 /tmp/specterd.tar.gz" | sha256sum -c -
tar xf /tmp/specterd.tar.gz -C ~
cd ~/specter-desktop-*

sed -i "s/vx.y.z-get-replaced-by-release-script/$SPECTER_VERSION/g; " setup.py
s6-setuidgid specter pip3 install --user .

# Run specter to generate the default config file, with invalid arguments
# that'll cause it to crash immediatly after creating it.
s6-setuidgid specter python3.7 -m cryptoadvance.specter server --host ! > /dev/null 2>&1 || true
[ -f ~/.specter/config.json ] || exit 1

# Symlink wallets/devices config directory to mark it for backup
ln -s /data/specter /important/

# Cleanup
apt-get purge -y python3.7-dev python3-pip python3-setuptools build-essential libudev-dev libusb-1.0-0-dev python3-wheel libffi-dev libssl-dev
rm -r ~/specter-desktop-* ~/.cache
