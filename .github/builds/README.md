# XLA builds

This directory contains Docker-based automated builds to run off-CI.

## Usage

The build can be run on any machine with Docker installed. First, you
need to build the image with CUDA/cuDNN and all other the dependencies

```shell
docker build -t xla-cuda111 -f Dockerfile.cuda --build-arg CUDA_VERSION=11.1.1 --build-arg XLA_TARGET=cuda111 .
docker build -t xla-cuda114 -f Dockerfile.cuda --build-arg CUDA_VERSION=11.4.3 --build-arg XLA_TARGET=cuda114 .
docker build -t xla-cuda118 -f Dockerfile.cuda --build-arg CUDA_VERSION=11.8.0 --build-arg XLA_TARGET=cuda118 .
```

Then, start a container. It clones XLA from GitHub, compiles and packages
the archive

```shell
docker run --rm -it -v $(pwd)/build:/build xla-cuda111
docker run --rm -it -v $(pwd)/build:/build xla-cuda114
docker run --rm -it -v $(pwd)/build:/build xla-cuda118
```

The archive ends up in the mounted `$(pwd)/build`.
