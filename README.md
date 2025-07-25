# XLA

<!-- Docs -->

Precompiled [XLA](https://github.com/openxla/xla) binaries for [EXLA](https://github.com/elixir-nx/nx/tree/main/exla).

Currently supports UNIX systems, including macOS (although no built-in support for Apple Metal).
Windows platforms are only supported upstream via [WSL](https://en.wikipedia.org/wiki/Windows_Subsystem_for_Linux).

## Usage

EXLA already depends on this package, so you generally don't need to install it yourself.
There is however a number of environment variables that you may want to use in order to
customize the variant of XLA binary.

The binaries are always built/downloaded to match the current configuration, so you should
set the environment variables in `.bash_profile` or a similar configuration file so you don't
need to export it in every shell session.

#### `XLA_TARGET`

The default value is usually `cpu`, which implies the final the binary supports targeting
only the host CPU. If a matching CUDA version is detected, the target is set to CUDA accordingly.

| Value | Target environment |
| --- | --- |
| cpu | |
| tpu | libtpu |
| cuda12 | CUDA >= 12.1, cuDNN >= 9.1 and < 10.0 |
| cuda | CUDA x.y, cuDNN (building from source only) |
| rocm | ROCm (building from source only) |

To use XLA with NVidia GPU you need [CUDA](https://developer.nvidia.com/cuda-downloads)
and [cuDNN](https://developer.nvidia.com/cudnn) compatible with your GPU drivers.
See [the installation instructions](https://docs.nvidia.com/deeplearning/cudnn/install-guide/index.html)
and [the cuDNN support matrix](https://docs.nvidia.com/deeplearning/cudnn/support-matrix/index.html)
for version compatibility. To use precompiled XLA binaries specify a target matching
your CUDA version (like `cuda12`). You can find your CUDA version by running `nvcc --version`
(note that `nvidia-smi` shows the highest supported CUDA version, not the installed one).
When building from source it's enough to specify `cuda` as the target.

Note that all precompiled Linux binaries assume glibc 2.31 or newer.

##### Notes for ROCm

For GPU support, we primarily rely on CUDA, because of the popularity and availability
in the cloud. In case you use ROCm and it does not work, please open up an issue and
we will be happy to help.

In addition to building in a local environment, you can build the ROCm binary using
the Docker-based scripts in [`builds/`](https://github.com/elixir-nx/xla/tree/main/builds). You may want to adjust the ROCm
version in `rocm.Dockerfile` accordingly.

When you encounter errors at runtime, you may want to set `ROCM_PATH=/opt/rocm-6.0.0`
and `LD_LIBRARY_PATH="/opt/rocm-6.0.0/lib"` (with your respective version). For further
issues, feel free to open an issue.

#### `XLA_BUILD`

Defaults to `false`. If `true` the binary is built locally, which may be intended
if no precompiled binary is available for your target environment. Once set, you
must run `mix deps.clean xla --build` explicitly to force XLA to recompile.
Building has a number of dependencies, see *Building from source* below.

#### `XLA_ARCHIVE_URL`

A URL pointing to a specific build of the `.tar.gz` archive. When using this option
you need to make sure the build matches your OS, CPU architecture and the XLA target.

#### `XLA_ARCHIVE_PATH`

Just like `XLA_ARCHIVE_URL`, but pointing to a local `.tar.gz` archive file.

#### `XLA_CACHE_DIR`

The directory to store the downloaded and built archives in. Defaults to the standard
cache location for the given operating system.

#### `XLA_TARGET_PLATFORM`

The target triplet describing the target platform, such as `aarch64-linux-gnu`. By default
this target is inferred for the host, however you may want to override this when cross-compiling
the project using Nerves.

## Building from source

> Note: currently only macOS and Linux is supported. When on Windows, the best option
> to use XLA and EXLA is by running inside WSL.

To build the XLA binaries locally you need to set `XLA_BUILD=true` and possibly `XLA_TARGET`.
Keep in mind that the compilation usually takes a very long time.

You will need the following installed in your system for the compilation:

  * [Git](https://git-scm.com/) for fetching XLA source
  * [Bazel v7.4.1](https://bazel.build/) for compiling XLA
  * [Clang 18](https://clang.llvm.org/) for compiling XLA
  * [Python3](https://python.org) with NumPy installed for compiling XLA

### Common issues

#### Bazel version

Use `bazel --version` to check your Bazel version, make sure you are using v7.4.1.
Most binaries are available on [Github](https://github.com/bazelbuild/bazel/releases),
but it can also be installed with `asdf`:

```shell
asdf plugin add bazel
asdf install bazel 7.4.1
asdf set -u bazel 7.4.1
```

#### Clang

XLA builds are known to work with Clang 18. On macOS clang comes as part of Xcode SDK
and the version may be older, though for macOS we have precompiled archives, so you
most likely don't need to worry about it.

#### Python and asdf

`Bazel` cannot find `python` installed via the `asdf` version manager by default. `asdf` uses a
function to lookup the specified version of a given binary, this approach prevents `Bazel` from
being able to correctly build XLA. The error is `unknown command: python. Perhaps you have to reshim?`.
There are two known workarounds:

1. Explicitly change your `$PATH` to point to a Python installation (note the build process
   looks for `python`, not `python3`). For example:

    ```shell
    # Point directly to a specific Python version
    export PATH=$HOME/.asdf/installs/python/3.10.8/bin:$PATH
    ```

2. Use the [`asdf direnv`](https://github.com/asdf-community/asdf-direnv) plugin to install [`direnv 2.20.0`](https://direnv.net).
   `direnv` along with the `asdf-direnv` plugin will explicitly set the paths for any binary specified
   in your project's `.tool-versions` files.

If you still get the error, you can also try setting `PYTHON_BIN_PATH`, like `export PYTHON_BIN_PATH=/usr/bin/python3.11`.

After doing any of the steps above, it may be necessary to clear the build cache by removing ` ~/.cache/xla_build`
(or the corresponding OS-specific cache location).

### GPU support

To build binaries with GPU support, you need all the GPU-specific dependencies (CUDA, ROCm),
then you can build with either `XLA_TARGET=cuda` or `XLA_TARGET=rocm`. See the `XLA_TARGET`
for more details.

### TPU support

All you need is setting `XLA_TARGET=tpu`.

### Compilation-specific environment variables

You can use the following env vars to customize your build:

  * `BUILD_CACHE` - controls where to store XLA source and builds

  * `BUILD_FLAGS` - additional flags passed to Bazel

  * `BUILD_MODE` - controls to compile `opt` (default) artifacts or `dbg`, example: `BUILD_MODE=dbg`

## Runtime flags

You can further configure XLA runtime options with `XLA_FLAGS`,
see: [xla/debug_options_flags.cc](https://github.com/openxla/xla/blob/main/xla/debug_options_flags.cc)
for the list of available flags.

<!-- Docs -->

## Release process

To publish a new version of this package:

1. Update version in `mix.exs`.
2. Create and push a new tag.
3. Wait for the release workflow to build all the binaries.
4. Publish the release from draft.
5. Publish the package to Hex.

## License

Note that the build artifacts are a result of compiling XLA, hence are under
the respective license. See [XLA](https://github.com/openxla/xla).

```text
Copyright (c) 2020 Sean Moriarity

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at [http://www.apache.org/licenses/LICENSE-2.0](http://www.apache.org/licenses/LICENSE-2.0)

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
