#!/bin/bash

set -e

git clone --depth 1 https://github.com/elixir-nx/xla.git
cd xla

mix deps.get

export XLA_CACHE_DIR=/build

XLA_BUILD=true mix compile

# We expect /build to be mounted, so we fix file permissions on the host
chown -R 1000:1000 /build
