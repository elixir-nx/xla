#!/bin/bash

set -ex

cd "$(dirname "$0")/../.."

sha="$1"
release_name="$2"
files="${@:3}"

# Create the release, if not present.
if ! gh release view $release_name; then
  gh release create $release_name --title $release_name --draft --target $sha
fi

# Uploading is the final action after several hour long build, so in
# case of any temporary network failures we want to retry a number
# of times.
for i in {1..10}; do
  gh release upload $release_name $files --clobber && break
  echo "Upload failed, retrying in 30s"
  sleep 30
done
