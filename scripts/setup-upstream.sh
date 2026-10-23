#!/bin/sh
# Fetch the pinned bendlang/bend checkout that holds tools/bend-lint (the linter)
# and src/bend/lint.bend (the rule API every rule here imports).
# Idempotent: a checkout already at the pinned commit is left alone.
set -eu

root=$(cd "$(dirname "$0")/.." && pwd)
. "$root/upstream.env"

dest="$root/upstream/bend"

if [ -d "$dest/.git" ] && [ "$(git -C "$dest" rev-parse HEAD)" = "$UPSTREAM_COMMIT" ]; then
  echo "upstream: $UPSTREAM_TAG at $UPSTREAM_COMMIT (ok)"
  exit 0
fi

mkdir -p "$root/upstream"
if [ ! -d "$dest/.git" ]; then
  git clone --quiet --depth 1 --branch "$UPSTREAM_TAG" "$UPSTREAM_URL" "$dest"
else
  git -C "$dest" fetch --quiet --depth 1 origin "refs/tags/$UPSTREAM_TAG:refs/tags/$UPSTREAM_TAG"
  git -C "$dest" checkout --quiet --detach "$UPSTREAM_TAG"
fi

actual=$(git -C "$dest" rev-parse HEAD)
if [ "$actual" != "$UPSTREAM_COMMIT" ]; then
  echo "upstream: $UPSTREAM_TAG is $actual, expected $UPSTREAM_COMMIT (upstream tag moved?)" >&2
  exit 1
fi
echo "upstream: $UPSTREAM_TAG at $actual (fetched)"
