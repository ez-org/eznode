#!/bin/bash
set -xeo pipefail
export DOCKER_CLI_EXPERIMENTAL=enabled

docker_name=shesek/eznode # FIXME
version=${1:?"Usage: $0 <version>"}

cd "$(dirname "$0")/.."

build_variant() {
  local tag=$docker_name:$1
  local tag_alias=$docker_name:$2
  local packages=$3

  for arch in amd64 arm arm64; do
    INSTALL=$packages ./docker/build-arch.sh $arch -t $tag-$arch
    docker push $tag-$arch
    sha256=$(docker inspect --format='{{index .RepoDigests 0}}' $tag-$arch | cut -d: -f2)
    echo "$sha256  $tag-$arch" | tee -a SHA256SUMS
  done

  # Can't alias multi-arch manifest images, have to create it twice.
  for name in $tag $tag_alias; do
    docker manifest create --amend $name $tag-amd64 $tag-arm $tag-arm64
    for arch in amd64 arm arm64; do
      docker manifest annotate $name $tag-$arch --os linux --arch $arch
    done
    docker manifest push $name -p
  done
}

# Extract unreleased changelog & update version number
changelog=$(sed -nr '/^## (Unreleased|'$version' )/{n;:a;n;/^## /q;p;ba}' CHANGELOG.md)
grep -q '## Unreleased' CHANGELOG.md && sed -i "s/^## Unreleased/## $version - $(date +%Y-%m-%d)/" CHANGELOG.md

echo -e "Releasing eznode v$version\n\n$changelog\n\n"

# Build & publish image variants for the various arches
if [ -z "$SKIP_BUILD" ]; then
  echo -n > SHA256SUMS
  #build_variant $version latest bitcoind,btc-rpc-explorer
  # FIXME latestx -> latest
  build_variant $version latestx bitcoind,bwt,btc-rpc-explorer,specter,tor,nginx,letsencrypt,dropbear
  #build_variant $version-local local bitcoind,bwt,specter,btc-rpc-explorer
  #build_variant $version-minimal minimal bitcoind,bwt

  sort -k2 SHA256SUMS | gpg --clearsign --digest-algo sha256 > SHA256SUMS.asc
  rm SHA256SUMS
fi

read -p y

if [ -z "$SKIP_GIT" ]; then
  echo Tagging...
  git add CHANGELOG.md SHA256SUMS.asc
  git commit -S -m v$version
  git tag --sign -m "$changelog" v$version
  git branch -f latest HEAD

  echo Pushing to github...
  git push gh master latest
  git push gh --tags
fi
