FROM hexpm/elixir:1.15.4-erlang-26.0.2-ubuntu-focal-20230126 AS elixir

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

ENV USE_BAZEL_VERSION 6.1.0

# Install Python and the necessary global dependencies
RUN apt-get install -y python3 python3-pip && \
  ln -s /usr/bin/python3 /usr/bin/python && \
  python -m pip install --upgrade pip numpy

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
