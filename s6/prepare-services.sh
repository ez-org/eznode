#!/bin/bash
set -eo pipefail
shopt -s extglob

# Set a default finish script and notification-fd
for dir in /run/s6/services/!(s6-*); do
  [ -f $dir/finish ] || ln -s /ez/default-finish.sh $dir/finish
  [ -f $dir/notification-fd ] || echo 5 > $dir/notification-fd
done
