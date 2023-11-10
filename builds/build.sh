#!/bin/bash

set -e

cd "$(dirname "$0")/.."

print_usage_and_exit() {
  echo "Usage: $0 <variant>"
  echo ""
  echo "Compiles the project inside docker. Available variants: cpu, cuda118, cuda120, tpu, rocm."
  exit 1
}

if [ $# -ne 1 ]; then
  print_usage_and_exit
fi

# For cuDNN support matrix see [1]. When precompiling, we want to use
# the lowest cuDNN that supports the given CUDA version.
#
# [1]: https://docs.nvidia.com/deeplearning/cudnn/archives/index.html

case "$1" in
  "cpu")
    docker build -t xla-cpu -f builds/cpu.Dockerfile \
      --build-arg XLA_TARGET=cpu \
      .

    docker run --rm \
      -v $(pwd)/builds/output/cpu/build:/build \
      -v $(pwd)/builds/output/cpu/.cache:/root/.cache \
      $XLA_DOCKER_FLAGS \
      xla-cpu
  ;;

  "tpu")
    docker build -t xla-tpu -f builds/cpu.Dockerfile \
      --build-arg XLA_TARGET=tpu \
      .

    docker run --rm \
      -v $(pwd)/builds/output/tpu/build:/build \
      -v $(pwd)/builds/output/tpu/.cache:/root/.cache \
      $XLA_DOCKER_FLAGS \
      xla-tpu
  ;;

  "cuda118")
    docker build -t xla-cuda118 -f builds/cuda.Dockerfile \
      --build-arg CUDA_VERSION=11.8.0 \
      --build-arg CUDNN_VERSION=8.6.0 \
      --build-arg XLA_TARGET=cuda118 \
      .

    docker run --rm \
      -v $(pwd)/builds/output/cuda118/build:/build \
      -v $(pwd)/builds/output/cuda118/.cache:/root/.cache \
      $XLA_DOCKER_FLAGS \
      xla-cuda118
  ;;

  "cuda120")
    docker build -t xla-cuda120 -f builds/cuda.Dockerfile \
      --build-arg CUDA_VERSION=12.1.0 \
      --build-arg CUDNN_VERSION=8.9.0 \
      --build-arg XLA_TARGET=cuda120 \
      .

    docker run --rm \
      -v $(pwd)/builds/output/cuda120/build:/build \
      -v $(pwd)/builds/output/cuda120/.cache:/root/.cache \
      $XLA_DOCKER_FLAGS \
      xla-cuda120
  ;;

  "rocm")
    docker build -t xla-rocm -f builds/rocm.Dockerfile \
      --build-arg XLA_TARGET=rocm \
      .

    docker run --rm \
      -v $(pwd)/builds/output/rocm/build:/build \
      -v $(pwd)/builds/output/rocm/.cache:/root/.cache \
      $XLA_DOCKER_FLAGS \
      xla-rocm
  ;;

  *)
    print_usage_and_exit
  ;;
esac
