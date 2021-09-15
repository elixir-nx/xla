#!/bin/bash

set -ex

cd "$(dirname "$0")/../.."

# Ensure tasks are compiled
mix compile

tag=$(mix xla.release_tag)

cd cache/build

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
