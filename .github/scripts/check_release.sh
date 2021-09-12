#!/bin/bash

set -ex

cd "$(dirname "$0")/../.."

tag=$(mix build.release_tag)

if gh release list | grep $tag; then
  archive_filename=$(mix build.release_archive_filename)

  if gh release view $tag | grep $archive_filename; then
    echo "::set-output name=continue::false"
  else
    echo "::set-output name=continue::true"
  fi
else
  echo "::error::Release $tag not found"
  exit 1
fi
