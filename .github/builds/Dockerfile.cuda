ARG CUDA_VERSION

FROM nvidia/cuda:${CUDA_VERSION}-cudnn8-devel-ubuntu20.04

ARG XLA_TARGET

# Set the missing UTF-8 locale, otherwise Elixir warns
ENV LC_ALL C.UTF-8

# Make sure installing packages (like tzdata) doesn't prompt for configuration
ENV DEBIAN_FRONTEND noninteractive

ENV XLA_TARGET ${XLA_TARGET}

# We need to install "add-apt-repository" first
RUN apt-get update && apt-get install -y software-properties-common && \
    # Add repository with the latest git version
    add-apt-repository ppa:git-core/ppa && \
    # Install basic system dependencies
    apt-get update && apt-get install -y ca-certificates curl git unzip wget

# Install Bazel
RUN apt-get install -y apt-transport-https curl gnupg && \
    curl -fsSL https://bazel.build/bazel-release.pub.gpg | gpg --dearmor > bazel.gpg && \
    mv bazel.gpg /etc/apt/trusted.gpg.d/ && \
    echo "deb [arch=amd64] https://storage.googleapis.com/bazel-apt stable jdk1.8" | tee /etc/apt/sources.list.d/bazel.list && \
    apt-get update && apt-get install -y bazel-5.3.0 && \
    ln -s /usr/bin/bazel-5.3.0 /usr/bin/bazel

# Install Python and the necessary global dependencies
RUN apt-get install -y python3 python3-pip && \
    ln -s /usr/bin/python3 /usr/bin/python && \
    python -m pip install --upgrade pip numpy

# Install Erlang and Elixir
RUN wget -q https://packages.erlang-solutions.com/erlang-solutions_2.0_all.deb && \
    dpkg -i "erlang-solutions_2.0_all.deb" && \
    apt-get update && apt-get install -y esl-erlang && apt-get install -y elixir && \
    mix local.hex --force && mix local.rebar --force

COPY docker-entrypoint.sh /docker-entrypoint.sh
ENTRYPOINT [ "/docker-entrypoint.sh" ]
