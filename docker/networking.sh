# -- expected to be `source`ed

export DOCKER_HOST_IP=$(getent hosts host.docker.internal | cut -d' ' -f1 2> /dev/null || return 0)

# Detect Docker on macOS. It behaves differently:
# https://docs.docker.com/docker-for-mac/networking/#known-limitations-use-cases-and-workarounds
IS_MACOS=$(uname -r | grep -Eq -- '-moby$|-linuxkit($|-)' && echo 1 || return 0)

# Detect Docker's networking mode and determine the address to bind on
if [ -z "$BIND_ADDR" ]; then
  addrs=$(hostname -I)
  
  # macOS doesn't support host networking mode and doesn't allow accessing the
  # container by its virtual IP address, so we can just bind on 0.0.0.0.
  if [ -n "$IS_MACOS" ]; then
    export BIND_ADDR=0.0.0.0

  # In a virtual docker network env, our hostname will resolve to a single IP
  # address in the 172.x.x.x range (there will typically be multiple on the host).
  # Bind on it explicitly instead of using 0.0.0.0 to make the services
  # URLs/URIs shown to the user easily accessible from the host.
  elif grep -Eq '^172\.\S+ ' <<< $addrs; then
    export BIND_ADDR=${addrs/ /}

  # Bind on 127.0.0.1 in host networking mode as a safety precaution
  else
    export BIND_ADDR=127.0.0.1
    warn networking "You appear to be running in docker host networking mode (--net host)." \
              "Services will be bound on 127.0.0.1 by default, to prevent them from accidentally being left exposed to the world." \
              "Set BIND_ADDR=0.0.0.0 if you'd like to accept remote connections."
    # This could be a false positive, if the user reconfigured docker's IP range.
    # I couldn't find a more reliable way to do this.
  fi
fi

# Automagically add an entry to /ez/hosts (mounted from the hosts's /etc/hosts)
if [ -f "/ez/hosts" ]; then
  [ -n "$IS_MACOS" ] && error networking The /ez/hosts alias feature is not supported on macOS
  export HOST_ALIAS=${HOST_ALIAS:-ez}
  cat <<< $(grep -v "^\S\+ $HOST_ALIAS\$" /ez/hosts) > /ez/hosts
  info networking Adding /etc/hosts entry: \
    $(echo "$(hostname -i) $HOST_ALIAS" | tee -a /ez/hosts)
  info networking "Your node will be available via the '$HOST_ALIAS' hostname"
fi

# Show instructions for local access on macOS
if [ -n "$IS_MACOS" ]; then
  warn networking "Accessing the container by its virtual IP address is not possible on macOS." \
                  "To access the services locally, you'll need to publish the ports with \`-p 127.0.0.1:<port>:<port>\` to make them available through localhost."$'\n' \
                  "For example: \$ docker run -it -v ~/eznode:/data -p 127.0.0.1:50001:50001 -p 127.0.0.1:3002:3002 eznode/eznode"
fi
