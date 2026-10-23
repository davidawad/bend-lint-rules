#!/bin/sh
# Lint this repo's own rules with the pack: every rule file must come out with no findings.
# common.bend is a library (no main), so every def in it is an entry (rules/common.bend-lint.json).
set -u

root=$(cd "$(dirname "$0")/.." && pwd)
status=0

lint_file() {
  file=$1
  shift
  out=$("$root/scripts/lint.sh" "$file" "$@" 2>&1)
  code=$?
  case "$out" in
    *"bend-lint: 0 finding(s)"*) [ "$code" -eq 0 ] && echo "ok   ${file#"$root"/}" && return 0 ;;
  esac
  echo "FAIL ${file#"$root"/}"
  printf '%s\n' "$out" | sed 's/^/    | /'
  status=1
}

for rule in "$root"/rules/*/*.bend; do
  lint_file "$rule"
done
lint_file "$root/rules/common.bend" --config "$root/rules/common.bend-lint.json"

exit "$status"
