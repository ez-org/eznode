#!/bin/bash
set -xeo pipefail

build_args='BASE_IMAGE INSTALL BWT_ARCH BWT_SHA256 BITCOIND_ARCH BITCOIND_SHA256 S6_OVERLAY_ARCH S6_OVERLAY_SHA256 NODEJS_ARCH NODEJS_SHA256'
dir="$(dirname "$0")"
arch=${1:?'Usage: $0 [amd64|arm|arm64] -t <name> [args...]'}; shift

# amd64 uses the default build args from the Dockerfile
[ "$arch" != "amd64" ] && source "$dir/$arch.env"

exec docker build "$@" $(for a in $build_args; do echo "--build-arg $a"; done) "$dir/.."
