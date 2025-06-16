#!/bin/bash

set -ex

dir="$(cd "$(dirname "$0")"; pwd)"
arch="$(uname -m)"

# if [[ $arch == 'aarch64' ]]; then
#   # ...
# fi

# XLA build links againast a major version of CUDA libraries, so the
# build should be compatible with CUDA installations across all minor
# versions. However, currently it also links againast a specific minor
# version nvrtc-builtins. That library is for debugging, it does not
# maintain compatibility across minor versions, and libraries should
# not link againast it. Looks like they only use symbols from that
# library for tests. The below patch changes the Bazel XLA build
# definitions to not link against nvrtc-builtins.
#
# See https://github.com/tensorflow/tensorflow/pull/86413 and the
# referenced threads.
git apply $dir/cuda_ncrtc_builtins.patch
