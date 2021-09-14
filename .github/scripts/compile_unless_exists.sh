#!/bin/bash

set -ex

cd "$(dirname "$0")/../.."

# Ensure tasks are compiled
mix compile

tag=$(mix xla.release_tag)

if gh release list | grep $tag; then
  archive_filename=$(mix xla.archive_filename)

  if gh release view $tag | grep $archive_filename; then
    echo "Found $archive_filename in $tag release artifacts, skipping compilation"
  else
    XLA_BUILD=true mix compile
  fi
else
  echo "::error::Release $tag not found"
  exit 1
fi
