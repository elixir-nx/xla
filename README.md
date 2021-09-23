# XLA

Precompiled Google's XLA binaries for [EXLA](https://github.com/elixir-nx/nx/tree/main/exla).

## Usage

EXLA already depends on this package, so you generally don't need to install it yourself.
There is however a number of environment variables that you may want to use in order to
customize the variant of XLA binary.

The binaries are always built/downloaded to match the current configuration, so you should
set the environment variables in `.bash_profile` or a similar configuration file so you don't
need to export it in every shell session.

#### `XLA_TARGET`

The default value is `cpu`, which implies the final the binary supports targeting
only the host CPU.

| Value | Target environment |
| --- | --- |
| cpu | |
| tpu | libtpu |
| cuda111 | CUDA 11.1+, cuDNN |
| cuda110 | CUDA 11.0, cuDNN |
| cuda102 | CUDA 10.2, cuDNN |
| cuda | CUDA x.y, cuDNN |
| rocm | ROCm |

To use XLA with NVidia GPU you need [CUDA](https://developer.nvidia.com/cuda-downloads)
and [cuDNN](https://developer.nvidia.com/cudnn) compatible with your GPU drivers.
See [the installation instructions](https://docs.nvidia.com/deeplearning/cudnn/install-guide/index.html)
and [the cuDNN support matrix](https://docs.nvidia.com/deeplearning/cudnn/support-matrix/index.html)
for version compatibility. To use precompiled XLA binaries specify a target matching
your CUDA version (like `cuda111`). When building from source it's enough to specify
`cuda` as the target.

#### `XLA_BUILD`

Defaults to `false`. If `true` the binary is built locally, which may be intended
if no precompiled binary is available for your target environment. If using XLA as
a dependency, you may need to run `mix deps.compile xla` explicitly after setting
this variable. Building has a number of dependencies, see *Building from source* below.

#### `XLA_ARCHIVE_URL`

A URL pointing to a specific build of the `.tar.gz` archive. When using this option
you need to make sure the build matches your OS, CPU architecture and the XLA target.

## Building from source

To build the XLA binaries locally you need to set `XLA_BUILD=true` and possibly `XLA_TARGET`.
Keep in mind that the compilation usually takes a very long time.

You will need the following installed in your system for the compilation:

  * [Git](https://git-scm.com/) for fetching Tensorflow source
  * [Bazel v3.7.2](https://bazel.build/) for compiling Tensorflow
  * [Python3](https://python.org) with NumPy installed for compiling Tensorflow

If running on Windows, you will also need:

  * [MSYS2](https://www.msys2.org/)
  * [Microsoft Build Tools 2019](https://visualstudio.microsoft.com/downloads/)
  * [Microsoft Visual C++ 2019 Redistributable](https://visualstudio.microsoft.com/downloads/)

### Common issues

#### Bazel version

Use `bazel --version` to check your Bazel version, make sure you are using v3.7.2.
Most binaries are available on [Github](https://github.com/bazelbuild/bazel/releases),
but it can also be installed with `asdf`:

```shell
asdf plugin-add bazel
asdf install bazel 3.7.2
asdf global bazel 3.7.2
```

#### GCC

You may have issues with newer and older versions of GCC. TensorFlow builds are known to work
with GCC versions between 7.5 and 9.3. If your system uses a newer GCC version, you can install
an older version and tell Bazel to use it with `export CC=/path/to/gcc-{version}` where version
is the GCC version you installed

#### Python and asdf

`Bazel` cannot find `python` installed via the `asdf` version manager by default. `asdf` uses a
function to lookup the specified version of a given binary, this approach prevents `Bazel` from
being able to correctly build XLA. The error is `unknown command: python. Perhaps you have to reshim?`.
There are two known workarounds:

1. Use a separate installer or explicitly change your `$PATH` to point to a Python installation (note
   the build process looks for `python`, not `python3`). For example, on Homebrew on macOS, you would do:

    ```shell
    export PATH=/usr/local/opt/python@3.9/libexec/bin:/usr/local/bin:$PATH
    ```

2. Use the [`asdf direnv`](https://github.com/asdf-community/asdf-direnv) plugin to install [`direnv 2.20.0`](https://direnv.net).
   `direnv` along with the `asdf-direnv` plugin will explicitly set the paths for any binary specified
   in your project's `.tool-versions` files.

If you still get the error, you can also try setting `PYTHON_BIN_PATH`, like `export PYTHON_BIN_PATH=/usr/bin/python3.9`.

After doing any of the steps above, it may be necessary to clear the build cache by removing ` ~/.cache/xla_extension`.

### GPU support

To build binaries with GPU support, you need all the GPU-specific dependencies (CUDA, ROCm),
then you can build with either `XLA_TARGET=cuda` or `XLA_TARGET=rocm`. See the `XLA_TARGET`
for more details.

### TPU support

All you need is setting `XLA_TARGET=tpu`.

### Apple Silicon

Building on Apple Silicon requires a newer version of Bazel, it's been verified
to work with `4.2.1`. You need to explicitly override the version by setting
`USE_BAZEL_VERSION=4.2.1`.

### Compilation-specific environment variables

You can use the following env vars to customize your build:

  * `BUILD_CACHE` - controls where to store Tensorflow source and builds

  * `BUILD_FLAGS` - additional flags passed to Bazel

  * `BUILD_MODE` - controls to compile `opt` (default) artifacts or `dbg`, example: `BUILD_MODE=dbg`

## Runtime flags

You can further configure XLA runtime options with `XLA_FLAGS`,
see: [tensorflow/compiler/xla/debug_options_flags.cc](https://github.com/tensorflow/tensorflow/blob/master/tensorflow/compiler/xla/debug_options_flags.cc)
for the list of available flags.

## Release process

To publish a new version of this package:

1. Update version in `mix.exs`.
2. Run `.github/scripts/publish_release.sh`.
3. Wait for the release workflow to build all the binaries.
4. Publish the package to Hex.

## License

Note that the build artifacts are a result of compiling Google XLA,
hence are under their own license. See [Tensorflow](https://github.com/tensorflow/tensorflow).

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
