#!/bin/bash
set -eo pipefail
source /ez/util.sh

wantup="$(s6-svstat -o wantedup . 2> /dev/null || return 0)"

if [ $1 -eq 0 ] || [ $1 -eq 256 ] || [ "$wantup" == false ]; then
  debug $(basename $PWD) exited with code $1
else
  warn $(basename $PWD) exited with error code $1
fi
