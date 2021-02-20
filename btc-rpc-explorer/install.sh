#!/bin/bash
set -xeo pipefail
shopt -s extglob

apt-get install -yqq --no-install-recommends git \
  $([[ $(dpkg --print-architecture) == "arm"* ]] && echo libatomic1)

useradd -m btcexp
adduser btcexp bitcoin

mkdir /var/log/btc-rpc-explorer && chown nobody /var/log/btc-rpc-explorer

export HOME=/home/btcexp
export PATH=$HOME/node/bin:$PATH

# Install nodejs
wget -qO /tmp/node.tar.gz https://nodejs.org/dist/v$NODEJS_VERSION/node-v$NODEJS_VERSION-$NODEJS_ARCH.tar.gz
echo "$NODEJS_SHA256 /tmp/node.tar.gz" | sha256sum -c -
tar xzf /tmp/node.tar.gz -C $HOME
mv $HOME/node-* $HOME/node && chown -R btcexp $HOME/node

# Install btc-rpc-explorer
# Use janoside/btc-rpc-explorer#feature-prune-support, pending https://github.com/janoside/btc-rpc-explorer/pull/279
wget -qO /tmp/btcexp.tar.gz https://github.com/janoside/btc-rpc-explorer/archive/$BTCEXP_COMMIT.tar.gz
echo "$BTCEXP_SHA256 /tmp/btcexp.tar.gz" | sha256sum -c -

# Trim js code down from 69MB to 3MB by bundling the entire tree into a single minified .js file.
# This doesn't work for native libraries (redis, dtrace & tiny-secp256k1), which appears to be acceptable.
# They could be made to work by keeping their dir in node_modules and instructing browserify to skip them with -x.
# They also require build-essential and python3 to be installed during the build.
s6-setuidgid btcexp bash -xeo pipefail << 'PRIV'
  echo The native nodejs libraries are going to fail and fallback to pure js implementations. This is normal.
  npm install -g /tmp/btcexp.tar.gz browserify terser
  if [ -n "$DEV" ]; then mv $HOME/node/lib/node_modules/btc-rpc-explorer $HOME/dist; exit 0; fi
  mkdir ~/dist ~/dist/bin
  cd $HOME/node/lib/node_modules/btc-rpc-explorer
  (cd bin && browserify --node -x v8 -x node-bitcoin-script -x async_hooks -x hiredis www \
    | terser -cm > ~/dist/bin/www)
  rm -r public/img/screenshots
  mv views public CHANGELOG.md ~/dist/
PRIV

# Cleanup
apt-get purge -y git
rm -rf $HOME/.{npm,cache} $HOME/node/!(bin)
