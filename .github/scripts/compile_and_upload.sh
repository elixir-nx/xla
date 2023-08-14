#!/bin/bash

set -ex

cd "$(dirname "$0")/../.."

tag=$1

# Ensure tasks are compiled
mix compile

if gh release list | grep $tag; then
  archive_filename=$(mix xla.info archive_filename)
  build_archive_dir=$(mix xla.info build_archive_dir)

  if gh release view $tag | grep $archive_filename; then
    echo "Found $archive_filename in $tag release artifacts, skipping compilation"
  else
    XLA_BUILD=true mix compile

    # Uploading is the final action after several hour long build,
    # so in case of any temporary network failures we want to retry
    # a number of times
    for i in {1..10}; do
      gh release upload --clobber $tag "$build_archive_dir/$archive_filename" && break
      echo "Upload failed, retrying in 30s"
      sleep 30
    done
  fi
else
  echo "::error::Release $tag not found"
  exit 1
fi
