# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [v0.8.0](https://github.com/elixir-nx/xla/tree/v0.8.0) (2024-08-17)

### Added

* Integrity verification when downloading the precompiled binaries ([#94](https://github.com/elixir-nx/xla/pull/94))

### Changed

* Bumped the version requirement for CUDA 12 to cuDNN 9.1+ ([#93](https://github.com/elixir-nx/xla/pull/93))
* Archive file names to include the release version
* Dropped the requirement for either `wget` or `curl` to be installed ([#94](https://github.com/elixir-nx/xla/pull/94))

### Removed

* Removed the `XLA_HTTP_HEADERS` environment variable ([#94](https://github.com/elixir-nx/xla/pull/94))

### Fixed

* Download failures due to GitHub API rate limiting on CI ([#94](https://github.com/elixir-nx/xla/pull/94))

## [v0.7.1](https://github.com/elixir-nx/xla/tree/v0.7.1) (2024-07-01)

### Changed

* `XLA_TARGET` to default to a matching target when CUDA installation is detected ([#88](https://github.com/elixir-nx/xla/pull/88))

## [v0.7.0](https://github.com/elixir-nx/xla/tree/v0.7.0) (2024-05-21)

### Changed

* Bumped XLA version ([#83](https://github.com/elixir-nx/xla/pull/83))
* Renamed the recognised XLA_TARGET "cuda120" to "cuda12" ([#84](https://github.com/elixir-nx/xla/pull/84))

### Removed

* Dropped support for CUDA 11.8+, now 12.1+ is required ([#84](https://github.com/elixir-nx/xla/pull/84))

## [v0.6.0](https://github.com/elixir-nx/xla/tree/v0.6.0) (2023-11-10)

### Changed

* Bumped XLA version ([#62](https://github.com/elixir-nx/xla/pull/62))

## [v0.5.1](https://github.com/elixir-nx/xla/tree/v0.5.1) (2023-09-14)

### Changed

* Bumped the version requirement for CUDA 12 to CUDA 12.1 and cuDNN 8.9 ([#54](https://github.com/elixir-nx/xla/pull/54))

## [v0.5.0](https://github.com/elixir-nx/xla/tree/v0.5.0) (2023-08-13)

### Added

* Support for custom http headers ([#44](https://github.com/elixir-nx/xla/pull/44))
* Support for CUDA 12

### Changed

* Migrated to OpenXLA source code ([#45](https://github.com/elixir-nx/xla/pull/45))

### Removed

* Dropped precompiled binary for CUDA 11.1 and CUDA 11.4
* Dropped precompiled binary for Linux musl

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
