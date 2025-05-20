ARG VARIANT
ARG BASE_IMAGE="hexpm/elixir:1.15.8-erlang-24.3.4.17-ubuntu-jammy-20250404"

# Pre-stages for base image variants

FROM ${BASE_IMAGE} AS base-cpu

FROM ${BASE_IMAGE} AS base-cuda

ARG CUDA_VERSION
ARG CUDNN_VERSION

ARG DEBIAN_FRONTEND=noninteractive

RUN distro="ubuntu$(. /etc/lsb-release; echo "$DISTRIB_RELEASE" | tr -d '.')" && \
  # Official Docker images use the sbsa packages when targetting arm64.
  # See https://gitlab.com/nvidia/container-images/cuda/-/blob/85f465ea3343a2d7f7753a0a838701999ed58a01/dist/12.5.1/ubuntu2204/base/Dockerfile#L12
  arch="$(if [ "$(uname -m)" = "aarch64" ]; then echo "sbsa"; else echo "x86_64"; fi)" && \
  apt-get update && apt-get install -y ca-certificates wget && \
  wget -qO /tmp/cuda-keyring.deb https://developer.download.nvidia.com/compute/cuda/repos/$distro/$arch/cuda-keyring_1.1-1_all.deb && \
  dpkg -i /tmp/cuda-keyring.deb && apt-get update && \
  apt-get install -y git cuda-toolkit-${CUDA_VERSION} libcudnn9-cuda-12=${CUDNN_VERSION}-1 libcudnn9-dev-cuda-12=${CUDNN_VERSION}-1 && \
  apt-get clean -y && rm -rf /var/lib/apt/lists/*

FROM ${BASE_IMAGE} AS base-rocm

ARG ROCM_VERSION

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates curl gnupg && \
  distro="$(. /etc/lsb-release && echo "$DISTRIB_CODENAME")" && \
  curl -sL https://repo.radeon.com/rocm/rocm.gpg.key | apt-key add - && \
  echo "deb [arch=amd64] https://repo.radeon.com/rocm/apt/${ROCM_VERSION}/ $distro main" | tee /etc/apt/sources.list.d/rocm.list && \
  printf 'Package: *\nPin: release o=repo.radeon.com\nPin-Priority: 600\n' | tee /etc/apt/preferences.d/rocm-pin-600 && \
  apt-get update && \
  apt-get install -y rocm-dev rocm-libs && \
  apt-get clean -y && rm -rf /var/lib/apt/lists/*

ENV ROCM_PATH "/opt/rocm-${ROCM_VERSION}.0"

FROM base-${VARIANT}

# Set the missing UTF-8 locale, otherwise Elixir warns
ENV LC_ALL=C.UTF-8

# Make sure installing packages (like tzdata) doesn't prompt for configuration
ARG DEBIAN_FRONTEND=noninteractive

# We need to install "add-apt-repository" first
RUN apt-get update && \
  # Install basic system dependencies
  apt-get update && apt-get install -y ca-certificates curl git unzip wget && \
  # Install Clang
  clang_version="18" && \
  apt-get install -y wget gnupg software-properties-common lsb-release && \
  wget -qO- https://apt.llvm.org/llvm.sh | bash -s -- $clang_version && \
  update-alternatives --install /usr/bin/clang clang /usr/bin/clang-$clang_version 100 && \
  update-alternatives --install /usr/bin/clang++ clang++ /usr/bin/clang++-$clang_version 100 && \
  apt-get clean -y && rm -rf /var/lib/apt/lists/*

# Install Bazel using Bazelisk (works for both amd and arm)
RUN wget -O bazel "https://github.com/bazelbuild/bazelisk/releases/download/v1.26.0/bazelisk-linux-$(dpkg --print-architecture)" && \
  chmod +x bazel && \
  mv bazel /usr/local/bin/bazel

ENV USE_BAZEL_VERSION=7.4.1

# Install Python and the necessary global dependencies
RUN apt-get update && apt-get install -y python3 python3-pip && \
  ln -s /usr/bin/python3 /usr/bin/python && \
  python -m pip install --upgrade pip numpy && \
  apt-get clean -y && rm -rf /var/lib/apt/lists/*

# Setup project files

WORKDIR /xla

ARG XLA_TARGET

ENV XLA_TARGET=${XLA_TARGET}
ENV XLA_CACHE_DIR=/build
ENV XLA_BUILD=true

COPY mix.exs mix.lock ./
RUN mix deps.get

COPY lib lib
COPY README.md Makefile ./
COPY extension extension

CMD [ "mix", "compile" ]
