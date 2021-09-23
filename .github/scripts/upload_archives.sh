#!/bin/bash

set -ex

cd "$(dirname "$0")/../.."

# Ensure tasks are compiled
mix compile

tag=$(mix xla.info release_tag)
build_archive_dir=$(mix xla.info build_archive_dir)
upload_dir=tmp/upload

if [[ -d $build_archive_dir ]]; then
  # Copy the archives into directory within this repo,
  # so that gh cli works within its context
  mkdir -p $upload_dir
  rm -f $upload_dir/*
  cp $build_archive_dir/* $upload_dir
  cd $upload_dir
else
  echo "Build directory not found"
  exit 1
fi

for file in *.tar.gz; do
  # Uploading is the final action after several hour long build,
  # so in case of any temporary network failures we want to retry
  # a number of times
  for i in {1..10}; do
    gh release upload --clobber $tag $file && break
    echo "Upload failed, retrying in 30s"
    sleep 30
  done
done
