#!/bin/sh
# Lint one Bend file with this pack: the rules in rules/ plus upstream's style/file-length.
#
#   scripts/lint.sh path/to/main.bend [bend-lint flags]     e.g. --json, --config file.json
#
# Lint the program's entry file: the program is that file and what it imports.
# The nearest bend-lint.json above the file sets options and severity (see bend-lint.json
# in this repo for the defaults); `--config` names another.
set -eu

root=$(cd "$(dirname "$0")/.." && pwd)
lint="$root/upstream/bend/tools/bend-lint/src/lint.ts"

[ -f "$lint" ] || sh "$root/scripts/setup-upstream.sh" >&2

# Rules are read from this repo, whatever the folder the file is in.
for rule in "$root"/rules/*/*.bend; do
  set -- "$@" --rules "$rule"
done
set -- "$@" --rules "$root/upstream/bend/tools/bend-lint/rules/file_length.bend"

exec bun "$lint" "$@"
