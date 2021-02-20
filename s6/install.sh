#!/bin/bash
set -eo pipefail
source /ez/util.sh
set -x

# Install s6-overlay
wget -qO /tmp/s6-overlay.tar.gz https://github.com/just-containers/s6-overlay/releases/download/v$S6_OVERLAY_VERSION/s6-overlay-$S6_OVERLAY_ARCH.tar.gz
echo "$S6_OVERLAY_SHA256  /tmp/s6-overlay.tar.gz" | sha256sum -c -
tar xzf /tmp/s6-overlay.tar.gz -C /

# Install utility for managing the s6 services
mv service /ez/bin/
for cmd in up down start stop restart reload logs status; do
  echo -e '#!/bin/sh\nexec service '$cmd' "$@"' >> /ez/bin/$cmd
  chmod +x /ez/bin/$cmd
done

# Display which services are in the process of shutting down
mv shutdown-status.sh /etc/cont-finish.d/

# Make the init-stage2 and init-stage3 scripts less verbose
sed -ri.bk '/"\[(s6-init|cont-finish\.d|fix-attrs\.d|cont-init\.d|services\.d|cmd)\] | "exited \$\{\?\}\." /d' \
  /etc/s6/init/init-stage{2,3}

# Keep some init-stage3 [s6-finish] log messages, but change their prefix
log_prefix=" ${GREEN}INFO${RESTORE}  ${BOLD}shutdown${RESTORE} > "
sed -ri '/"\[s6-finish\] waiting for services/d' /etc/s6/init/init-stage3
sed -ri "s/\[s6-finish\] /$log_prefix/" /etc/s6/init/init-stage3
