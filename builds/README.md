# XLA builds

This directory contains Docker-based automated builds to run off-CI.

## Usage

Run the build script, passing one of the defined variants.

```shell
./build.sh cuda118
```

When running on a remote server, it's important to detach the process,
so that it keeps running if the ssh connection is closed:

```shell
nohup time builds/build.sh cuda118 > build.log 2>&1 &
tail -f build.log
```

To see the built archives run:

```shell
ls output/*/build/*/cache/build/*.tar.gz
```
