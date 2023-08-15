ARG CUDA_VERSION

FROM hexpm/elixir:1.15.4-erlang-26.0.2-ubuntu-focal-20230126 AS elixir

FROM nvidia/cuda:${CUDA_VERSION}-cudnn8-devel-ubuntu20.04

ARG CUDNN_VERSION

# Set the missing UTF-8 locale, otherwise Elixir warns
ENV LC_ALL C.UTF-8

# Make sure installing packages (like tzdata) doesn't prompt for configuration
ENV DEBIAN_FRONTEND noninteractive

# We need to install "add-apt-repository" first
RUN apt-get update && apt-get install -y software-properties-common && \
  # Add repository with the latest git version
  add-apt-repository ppa:git-core/ppa && \
  # Install basic system dependencies
  apt-get update && apt-get install -y ca-certificates curl git unzip wget

# Install a specific cuDNN version over the default one
RUN cuda_version="${CUDA_VERSION}" && \
  cudnn_version="${CUDNN_VERSION}" && \
  cudnn_package_version="$(apt-cache madison libcudnn8 | grep -o "${cudnn_version}.*-1+cuda${cuda_version%.*}")" && \
  apt-get install -y --allow-downgrades --allow-change-held-packages libcudnn8=$cudnn_package_version libcudnn8-dev=$cudnn_package_version

# Install Bazel
RUN apt-get install -y apt-transport-https curl gnupg && \
  curl -fsSL https://bazel.build/bazel-release.pub.gpg | gpg --dearmor > bazel.gpg && \
  mv bazel.gpg /etc/apt/trusted.gpg.d/ && \
  echo "deb [arch=amd64] https://storage.googleapis.com/bazel-apt stable jdk1.8" | tee /etc/apt/sources.list.d/bazel.list && \
  apt-get update && apt-get install -y bazel-5.3.0 && \
  ln -s /usr/bin/bazel-5.3.0 /usr/bin/bazel

ENV USE_BAZEL_VERSION 5.3.0

# Install Python and the necessary global dependencies
RUN apt-get install -y python3 python3-pip && \
  ln -s /usr/bin/python3 /usr/bin/python && \
  python -m pip install --upgrade pip numpy

# Install Erlang and Elixir

# Erlang runtime dependencies, see https://github.com/hexpm/bob/blob/3b5721dccdfe9d59766f374e7b4fb7fb8a7c720e/priv/scripts/docker/erlang-ubuntu-focal.dockerfile#L41-L45
RUN apt-get install -y --no-install-recommends libodbc1 libssl1.1 libsctp1

# We copy the top-level directory first to preserve symlinks in /usr/local/bin
COPY --from=elixir /usr/local /usr/ELIXIR_LOCAL
RUN cp -r /usr/ELIXIR_LOCAL/lib/* /usr/local/lib && \
  cp -r /usr/ELIXIR_LOCAL/bin/* /usr/local/bin && \
  rm -rf /usr/ELIXIR_LOCAL

# ---

ARG XLA_TARGET

ENV XLA_TARGET=${XLA_TARGET}
ENV XLA_CACHE_DIR=/build
ENV XLA_BUILD=true

COPY mix.exs mix.lock ./
RUN mix deps.get

COPY lib lib
COPY Makefile Makefile.win ./
COPY extension extension

CMD [ "mix", "compile" ]
