#!/usr/bin/env bash

set -o verbose
set -o errexit

docker run \
  --rm \
  --privileged \
  -v /dev:/dev \
  -v ${PWD}:/build \
  -e "PKR_VAR_sha=$(git rev-parse --short HEAD)" \
  -e "PKR_VAR_repo=$(git config --get remote.origin.url)" \
  -e PACKER_CACHE_DIR=/build/packer_cache \
  --entrypoint /bin/sh \
  --workdir /build \
  ghcr.io/solo-io/packer-plugin-arm-image \
  -c 'sudo mount binfmt_misc -t binfmt_misc /proc/sys/fs/binfmt_misc && packer init ./ && packer build ./'
