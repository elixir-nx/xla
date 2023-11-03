# ARG CUDA_VERSION

FROM hexpm/elixir:1.15.4-erlang-26.0.2-ubuntu-focal-20230126 AS elixir

# FROM rocm/tensorflow:rocm5.7-tf2.13-dev
FROM rocm/dev-ubuntu-20.04:5.7-complete

# ARG CUDNN_VERSION

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

# Install Bazel using Bazelisk (works for both amd and arm)
RUN wget -O bazel "https://github.com/bazelbuild/bazelisk/releases/download/v1.18.0/bazelisk-linux-$(dpkg --print-architecture)" && \
  chmod +x bazel && \
  mv bazel /usr/local/bin/bazel

ENV USE_BAZEL_VERSION 6.1.2

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

ENV TF_ROCM_AMDGPU_TARGETS "gfx900,gfx906,gfx908,gfx90a,gfx1030"
ENV ROCM_PATH "/opt/rocm-5.7.0"

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
