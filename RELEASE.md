# Releasing XLA

1. Update version in `mix.exs` and update CHANGELOG.
2. Run `git tag x.y.z` and `git push --tags`.
   1. Wait for CI to precompile all artifacts.
   2. Build the remaining artifacts off-CI and upload to the draft GH release.
3. Publish GH release with copied changelog notes (CI creates a draft, we need to publish it to compute the checksum).
4. Run `mix xla.checksum`.
5. Run `mix hex.publish`.
