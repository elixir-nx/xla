# XLA builds

This directory contains Docker-based automated builds to run off-CI.

## Usage

The build can be run on any machine with Docker installed. First, you
need to build the image with CUDA/cuDNN and all other the dependencies

```shell
docker build -t xla-cuda111 -f Dockerfile.cuda111 .
```

Then, start a container. It clones XLA from GitHub, compiles and packages
the archive

```shell
docker run -it -v $(pwd)/build:/build xla-cuda111
```

The archive ends up in the mounted `$(pwd)/build`.
