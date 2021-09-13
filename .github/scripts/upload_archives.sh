#!/bin/bash

set -ex

cd "$(dirname "$0")/../.."

tag=$(mix xla.release_tag)

cd cache/build

for file in *.tar.gz; do
  gh release upload --clobber $tag $file
done
