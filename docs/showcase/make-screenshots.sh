#!/bin/sh
# Regenerate the README screenshot from real `blr lint` output on a generic fixture.
# Needs: a built blr (target/debug/blr, else this builds it), `just setup` done, and ImageMagick.
set -eu
root=$(cd "$(dirname "$0")/../.." && pwd)
cd "$root"
[ -x target/debug/blr ] || cargo build --quiet
fix=fixtures/dead/def/fail_transitive
out=docs/showcase/dead-def.txt
{
  printf '$ blr lint main.bend\n\n'
  (cd "$fix" && "$root/target/debug/blr" lint main.bend 2>&1 | sed 's/\. Delete it.*$/./')
} > "$out"
magick -background '#1e1e2e' -fill '#cdd6f4' -font "${FONT:-/System/Library/Fonts/Menlo.ttc}" -pointsize 15 "label:@$out" \
  -bordercolor '#1e1e2e' -border 24 -strip -colors 64 docs/showcase/dead-def.png
ls -l docs/showcase/dead-def.png
