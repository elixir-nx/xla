# XLA builds

This directory contains Docker-based automated builds to run off-CI.

## Usage

The build can be run on any machine with Docker installed. First, you
need to build the image with CUDA/cuDNN and all other the dependencies

```shell
docker build -t xla-cuda118 -f cuda.Dockerfile --build-arg CUDA_VERSION=11.8.0 --build-arg XLA_TARGET=cuda118 .
docker build -t xla-cuda120 -f cuda.Dockerfile --build-arg CUDA_VERSION=12.0.0 --build-arg XLA_TARGET=cuda120 .
```

Then, start a container. It clones XLA from GitHub, compiles and packages
the archive

```shell
docker run --rm -it -v $(pwd)/build:/build xla-cuda118
docker run --rm -it -v $(pwd)/build:/build xla-cuda120
```

The archive ends up in the mounted `$(pwd)/build`.
