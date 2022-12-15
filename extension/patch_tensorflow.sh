#!/bin/bash

set -ex

# detect if on musl and apply patch if we are
libc="$(if command -v ldd > /dev/null; then ldd /bin/ls | grep 'musl' | head -1 | cut -d ' ' -f1; fi)"
if [ ! -z $libc ]; then
  git apply tensorflow-alpine.patch
fi
