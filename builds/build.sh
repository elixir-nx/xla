#!/bin/bash

set -e

cd "$(dirname "$0")/.."

print_usage_and_exit() {
  echo "Usage: $0 <target>"
  echo ""
  echo "Compiles the project inside docker. Available targets: cpu, cuda12, tpu, rocm."
  exit 1
}

if [ $# -ne 1 ]; then
  print_usage_and_exit
fi

target="$1"

case "$target" in
  "cpu")
    docker build -t xla-cpu -f builds/Dockerfile \
      --build-arg VARIANT=cuda \
      --build-arg XLA_TARGET=cpu \
      .
  ;;

  "tpu")
    docker build -t xla-tpu -f builds/Dockerfile \
      --build-arg VARIANT=cpu \
      --build-arg XLA_TARGET=tpu \
      .
  ;;

  "cuda12")
    # docker build -t xla-cuda12 -f builds/Dockerfile \
    #   --build-arg VARIANT=cuda \
    #   --build-arg CUDA_VERSION=12-3 \
    #   --build-arg CUDNN_VERSION=9.1.1.17 \
    #   --build-arg XLA_TARGET=cuda12 \
    #   .
    docker build -t xla-cuda12 -f builds/Dockerfile \
      --build-arg VARIANT=cuda \
      --build-arg XLA_TARGET=cuda12 \
      .
  ;;

  "rocm")
    docker build -t xla-rocm -f builds/Dockerfile \
      --build-arg VARIANT=rocm \
      --build-arg ROCM_VERSION=6.0 \
      --build-arg XLA_TARGET=rocm \
      .
  ;;

  *)
    print_usage_and_exit
  ;;
esac

docker run --rm \
  -v $(pwd)/builds/output/$target/build:/build \
  -v $(pwd)/builds/output/$target/.cache:/root/.cache \
  $XLA_DOCKER_FLAGS \
  xla-$target
