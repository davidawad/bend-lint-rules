#!/bin/sh
# Run every fixture case against its rule and check the expectations.
#
#   tests/run.sh                    all cases
#   tests/run.sh dead/def           the cases of one rule
#   tests/run.sh dead/def/pass_x    one case
#
# A case is a folder fixtures/<group>/<rule>/<case>/ with
#   main.bend         the file linted (the entry file; it may import siblings)
#   bend-lint.json    options and severity for the rule (the case's own, never a parent's)
#   rule              optional: the rule file, as a path from the repo root, when it is not rules/<group>/<rule>.bend
#   expect            one expectation per line:
#                       exit N          bend-lint's exit code
#                       findings N      the number of diagnostics printed
#                       contains TEXT   TEXT appears in the output (fixed string)
#                       lacks TEXT      TEXT does not appear in the output
#                     blank lines and lines starting with # are ignored
# The rule under test is rules/<group>/<rule>.bend.
set -u

root=$(cd "$(dirname "$0")/.." && pwd)
lint="$root/upstream/bend/tools/bend-lint/src/lint.ts"
filter="${1:-}"

if [ ! -f "$lint" ]; then
  echo "tests: upstream bend-lint is missing; run scripts/setup-upstream.sh (just setup)" >&2
  exit 2
fi

pass=0
fail=0
failed=""

check_case() {
  dir=$1
  rel=${dir#"$root"/fixtures/} # group/rule/case
  rule=${rel%/*}               # group/rule
  rulefile="$root/rules/$rule.bend"
  [ ! -f "$dir/rule" ] || rulefile="$root/$(cat "$dir/rule")"
  out=$(cd "$dir" && bun "$lint" main.bend --rules "$rulefile" 2>&1)
  code=$?
  problems=""

  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in
      '' | '#'*) continue ;;
      'exit '*)
        want=${line#exit }
        [ "$code" = "$want" ] || problems="$problems\n    exit: want $want, got $code"
        ;;
      'findings '*)
        want=${line#findings }
        got=$(printf '%s\n' "$out" | grep -cE '^(Error|Warning|Information|Hint) \[')
        [ "$got" = "$want" ] || problems="$problems\n    findings: want $want, got $got"
        ;;
      'contains '*)
        want=${line#contains }
        printf '%s\n' "$out" | grep -qF -- "$want" || problems="$problems\n    missing: $want"
        ;;
      'lacks '*)
        want=${line#lacks }
        if printf '%s\n' "$out" | grep -qF -- "$want"; then problems="$problems\n    unexpected: $want"; fi
        ;;
      *)
        problems="$problems\n    bad expectation line: $line"
        ;;
    esac
  done < "$dir/expect"

  if [ -z "$problems" ]; then
    pass=$((pass + 1))
    echo "ok   $rel"
  else
    fail=$((fail + 1))
    failed="$failed $rel"
    echo "FAIL $rel"
    printf '%b\n' "$problems"
    printf '%s\n' "$out" | sed 's/^/    | /'
  fi
}

for expect in $(find "$root/fixtures" -name expect | sort); do
  dir=$(dirname "$expect")
  rel=${dir#"$root"/fixtures/}
  case "$rel" in
    "$filter"*) check_case "$dir" ;;
  esac
done

echo
echo "$pass passed; $fail failed"
[ "$fail" -eq 0 ] && [ "$pass" -gt 0 ]
