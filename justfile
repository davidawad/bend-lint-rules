set shell := ["sh", "-eu", "-c"]

blr := "cargo run --quiet --"

# List the recipes.
default:
    @just --list

# Fetch the pinned bendlang/bend checkout (bend-lint and its rule API) into upstream/bend.
setup:
    {{ blr }} setup

# Fail unless bend is the version in .bend-version and bun is new enough.
check-versions:
    {{ blr }} check-versions

# Run the fixture cases: bend-lint against each fixture, asserting exit code and output.
# `just test dead/def` runs one rule's cases; `just test dead/def/pass_basic` one case.
test filter="":
    {{ blr }} test {{ filter }}

# Lint this repo's own rules with the pack.
self:
    {{ blr }} self

# Everything CI runs: version pins, upstream checkout, fixtures, self-lint.
ci: check-versions setup test self
