# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [v0.4.4](https://github.com/elixir-nx/xla/tree/v0.4.4) (2023-02-17)

### Added

* Sorting library ([#39](https://github.com/elixir-nx/xla/pull/39))

## [v0.4.3](https://github.com/elixir-nx/xla/tree/v0.4.3) (2022-12-15)

### Fixed

* Building with `XLA_BUILD` (regression from v0.4.2) ([#33](https://github.com/elixir-nx/xla/pull/33))

## [v0.4.2](https://github.com/elixir-nx/xla/tree/v0.4.2) (2022-12-15)

### Added

* Precompiled binaries for Linux musl ([#31](https://github.com/elixir-nx/xla/pull/31))

### Fixed

* Partially fixed building for ROCm, see [notes](https://github.com/elixir-nx/xla/blob/e0352a1769ecdb93f7c829f7f184fd2b81d6ad3f/README.md#notes-for-rocm) ([#30](https://github.com/elixir-nx/xla/pull/30))

## [v0.4.1](https://github.com/elixir-nx/xla/tree/v0.4.1) (2022-12-08)

### Added

* Precompiled binaries for CUDA 11.4+ (cuDNN 8.2+) and CUDA 11.8+ (cuDNN 8.6+) ([#27](https://github.com/elixir-nx/xla/pull/27))

### Changed

* Precompiled binaries to assume glibc 31+ ([#27](https://github.com/elixir-nx/xla/pull/27))

## [v0.4.0](https://github.com/elixir-nx/xla/tree/v0.4.0) (2022-11-20)

### Changed

* Bumped XLA (Tensorflow) version to 2.11.0 ([#25](https://github.com/elixir-nx/xla/pull/25))

## [v0.3.0](https://github.com/elixir-nx/xla/tree/v0.3.0) (2022-02-17)

### Changed

* Bumped XLA (Tensorflow) version to 2.8.0 ([#15](https://github.com/elixir-nx/xla/pull/15))

### Removed

* Dropped support for CUDA 10.2 and 11.0, now 11.1+ is required ([#17](https://github.com/elixir-nx/xla/pull/17))

## [v0.2.0](https://github.com/elixir-nx/xla/tree/v0.2.0) (2021-09-23)

### Added

* Added support for Apple Silicon ([#9](https://github.com/elixir-nx/xla/pull/9))

### Changed

* Bumped XLA (Tensorflow) version to 2.6.0 ([#9](https://github.com/elixir-nx/xla/pull/9))

## [v0.1.1](https://github.com/elixir-nx/xla/tree/v0.1.1) (2021-09-16)

### Changed

* Build for older glibc versions ([#3](https://github.com/elixir-nx/xla/pull/3))

## [v0.1.0](https://github.com/elixir-nx/xla/tree/v0.1.0) (2021-09-16)

Initial release.
