#!/bin/bash

set -e

cd "$(dirname "$0")/.."

print_usage_and_exit() {
  echo "Usage: $0 <target>"
  echo ""
  echo "Compiles the project inside docker. Available targets: cpu, cuda12, cuda13, tpu, rocm."
  echo ""
  echo "Environment variables:"
  echo "  ROCM_VERSION  - ROCm version for rocm target (default: 6.3)"
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
    # Note that the versions are configured with HERMETIC_CUDA_VERSION
    # in lib/xla.ex.
    docker build -t xla-cuda12 -f builds/Dockerfile \
      --build-arg VARIANT=cuda \
      --build-arg XLA_TARGET=cuda12 \
      .
  ;;

  "cuda13")
    # Note that the versions are configured with HERMETIC_CUDA_VERSION
    # in lib/xla.ex.
    docker build -t xla-cuda13 -f builds/Dockerfile \
      --build-arg VARIANT=cuda \
      --build-arg XLA_TARGET=cuda13 \
      .
  ;;

  "rocm")
    # ROCm 6.2+ required: OpenXLA depends on rocprofiler-sdk (introduced in ROCm 6.2)
    # See https://github.com/openxla/xla/blob/main/third_party/gpus/rocm_configure.bzl
    rocm_ver="${ROCM_VERSION:-6.3}"
    rocm_major="${rocm_ver%%.*}"
    # Use version-specific output directory and image tag
    target="rocm-${rocm_ver}"
    # ROCm 7.x requires Ubuntu 22.04 (Jammy), older versions use Ubuntu 20.04 (Focal)
    if [ "$rocm_major" -ge 7 ]; then
      base_image="docker.io/hexpm/elixir:1.15.8-erlang-26.2.5.6-ubuntu-jammy-20240808"
    else
      base_image="docker.io/hexpm/elixir:1.15.8-erlang-24.3.4.17-ubuntu-focal-20240427"
    fi
    docker build -t xla-rocm-${rocm_ver} -f builds/Dockerfile \
      --build-arg VARIANT=rocm \
      --build-arg BASE_IMAGE=$base_image \
      --build-arg ROCM_VERSION=$rocm_ver \
      --build-arg XLA_TARGET=rocm \
      .
  ;;

  *)
    print_usage_and_exit
  ;;
esac

docker run --rm \
  -v $(pwd)/builds/output/$target/cache:/cache \
  -v $(pwd)/builds/output/$target/.cache:/root/.cache \
  $XLA_DOCKER_FLAGS \
  xla-$target
