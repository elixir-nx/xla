#!/bin/bash

set -ex

tmpf=/tmp/musl.log

# detect if on musl and apply patch if we are
libc=$(ldd /bin/ls | grep 'musl' | head -1 | cut -d ' ' -f1)
if [ ! -z $libc ]; then
  git apply tensorflow-alpine.patch
fi