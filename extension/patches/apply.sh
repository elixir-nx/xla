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

# When building XLA with ROCm, the compiler resolves symlinks in the
# local_config_rocm repository and reports include paths at the real
# absolute location (e.g. /opt/rocm/llvm/lib/clang/22/include)
# rather than the symlinked bazel-cache path. Bazel's header
# validation rejects these as "absolute path inclusions" unless they
# are listed in cxx_builtin_include_directories. This patch adds
# the absolute resource directory paths alongside the relative ones.
if [[ -n "${XLA_TARGET:-}" && "${XLA_TARGET}" == "rocm" ]]; then
  git apply $dir/rocm_absolute_includes.patch
fi
