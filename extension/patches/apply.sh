#!/bin/bash

set -ex

dir="$(cd "$(dirname "$0")"; pwd)"
arch="$(uname -m)"

if [[ $arch == 'aarch64' ]]; then
  # See https://github.com/tensorflow/tensorflow/issues/62490#issuecomment-2077646521
  git apply $dir/absl_workspace.patch
  cp $dir/absl_neon.patch third_party/tsl/third_party/absl
fi
