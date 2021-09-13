#!/bin/bash

set -e

cd "$(dirname "$0")/../.."

tag=$(mix xla.release_tag)

if gh release list | grep -q $tag; then
  echo "Release $tag already exists, make sure to bump the version in mix.exs"
  exit 1
fi

if [[ $(git diff @ @{upstream} | wc -c) -ne 0 ]]; then
  echo "Your git working directory is not up to date with remote, make sure to push the changes first"
  exit 1
fi

read -p "This will publish a new release $tag and trigger the release build. Do you want to continue? [y/N] "
if [[ ! $REPLY =~ ^[yY]$ ]]; then
  exit 0
fi

gh release create $tag --notes ""

echo "Successfully created release $tag. Remember to wait for the release build to finish before publishing the Hex package."
