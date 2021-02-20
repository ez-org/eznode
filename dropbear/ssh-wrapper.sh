#!/usr/bin/env -S justc-envdir /var/run/s6/container_environment bash

# Wrapper script for SSH clients (set with forced_command) to make environment variable options
# available in SSH sessions (via justc-envdir in the shebang) and to display a welcome banner.

if [ -n "$SSH_ORIGINAL_COMMAND" ] ; then
  exec $SSH_ORIGINAL_COMMAND

else
  banner 2> /dev/null || true
  exec $SHELL
fi
