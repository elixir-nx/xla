#!/bin/bash

set -ex

cd "$(dirname "$0")/../.."

tag=$(mix build.release_tag)
archive_filename=$(mix build.release_archive_filename)
build_archive_path=$(mix build.archive_path)

cp $build_archive_path $archive_filename
gh release upload --clobber $tag $archive_filename
