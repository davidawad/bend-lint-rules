#!/bin/sh
# Fail unless the tools are the ones this repo is pinned to.
#   Bend: `bend version` must equal the line in .bend-version (upstream.env pins bend-lint's own source).
#   Bun:  1.2 or newer, which bend-lint needs.
# BEND names the bend binary when it is not on PATH.
set -eu

root=$(cd "$(dirname "$0")/.." && pwd)
bend="${BEND:-bend}"
status=0

want=$(cat "$root/.bend-version")
if ! got=$("$bend" version 2> /dev/null); then
  echo "versions: cannot run \`$bend version\` (put bend on PATH or set BEND)" >&2
  exit 1
fi
if [ "$got" != "$want" ]; then
  echo "versions: bend is \"$got\", this repo is pinned to \"$want\" (.bend-version)" >&2
  echo "versions: install the pinned Bend, or re-run the tests on the new one and update .bend-version" >&2
  status=1
else
  echo "versions: $got (ok)"
fi

if ! bun_got=$(bun --version 2> /dev/null); then
  echo "versions: bun is not installed (bend-lint needs Bun 1.2 or newer)" >&2
  exit 1
fi
lowest=$(printf '1.2.0\n%s\n' "$bun_got" | sort -V | head -n 1)
if [ "$lowest" != "1.2.0" ]; then
  echo "versions: bun $bun_got is older than 1.2" >&2
  status=1
else
  echo "versions: bun $bun_got (ok)"
fi

exit "$status"
