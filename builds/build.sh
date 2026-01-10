#!/bin/bash

set -e

cd "$(dirname "$0")/.."

# Auto-detect container runtime (prefer podman if available)
if command -v podman &> /dev/null; then
  CONTAINER_RT="podman"
  # SELinux volume label for podman
  VOL_LABEL=":Z"
else
  CONTAINER_RT="docker"
  VOL_LABEL=""
fi

print_usage_and_exit() {
  echo "Usage: $0 <target>"
  echo ""
  echo "Compiles the project inside docker. Available targets: cpu, cuda12, tpu, rocm."
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
    $CONTAINER_RT build -t xla-cpu -f builds/Dockerfile \
      --build-arg VARIANT=cuda \
      --build-arg XLA_TARGET=cpu \
      .
  ;;

  "tpu")
    $CONTAINER_RT build -t xla-tpu -f builds/Dockerfile \
      --build-arg VARIANT=cpu \
      --build-arg XLA_TARGET=tpu \
      .
  ;;

  "cuda12")
    # Note that the versions are configured with HERMETIC_CUDA_VERSION
    # in lib/xla.ex.
    $CONTAINER_RT build -t xla-cuda12 -f builds/Dockerfile \
      --build-arg VARIANT=cuda \
      --build-arg XLA_TARGET=cuda12 \
      .
  ;;

  "rocm")
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
    $CONTAINER_RT build -t xla-rocm-${rocm_ver} -f builds/Dockerfile \
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

$CONTAINER_RT run --rm \
  -v $(pwd)/builds/output/$target/cache:/cache$VOL_LABEL \
  -v $(pwd)/builds/output/$target/.cache:/root/.cache$VOL_LABEL \
  $XLA_DOCKER_FLAGS \
  xla-$target
