//! Fail unless the tools are the ones this repo is pinned to.
//!   Bend: `bend version` must equal the line in .bend-version (upstream.env pins bend-lint's source).
//!   Bun:  1.2 or newer, which bend-lint needs.
//! `BEND` names the bend binary when it is not on PATH.
use crate::proc::{bun, run, strs};
use std::fs;
use std::path::Path;

const MIN_BUN: (u32, u32) = (1, 2);

/// Whether `version` (`1.3.3`) is at least `major.minor`.
pub fn at_least(version: &str, (major, minor): (u32, u32)) -> bool {
    let mut parts = version
        .trim()
        .split('.')
        .map(|part| part.parse::<u32>().unwrap_or(0));
    let (a, b) = (parts.next().unwrap_or(0), parts.next().unwrap_or(0));
    a > major || (a == major && b >= minor)
}

fn bend_problem(root: &Path) -> Option<String> {
    let want = fs::read_to_string(root.join(".bend-version")).unwrap_or_default();
    let want = want.trim();
    let bend = std::env::var("BEND").unwrap_or_else(|_| "bend".to_string());
    match run(&bend, &strs(["version"]), root) {
        Err(_) => Some(format!("cannot run `{bend} version` (put bend on PATH or set BEND)")),
        Ok(ran) if ran.code != 0 => Some(format!("`{bend} version` exits {}", ran.code)),
        Ok(ran) if ran.out.trim() == want => None,
        Ok(ran) => Some(format!(
            "bend is \"{}\", this repo is pinned to \"{want}\" (.bend-version). Install the pinned Bend, \
             or run the tests on the new one and update .bend-version and upstream.env",
            ran.out.trim()
        )),
    }
}

fn bun_problem(root: &Path) -> Option<String> {
    match run(&bun(), &strs(["--version"]), root) {
        Err(_) => Some("bun is not installed (bend-lint needs Bun 1.2 or newer)".to_string()),
        Ok(ran) if at_least(&ran.out, MIN_BUN) => None,
        Ok(ran) => Some(format!("bun {} is older than 1.2", ran.out.trim())),
    }
}

/// What is wrong with the tools, one line each; empty when all is as pinned.
pub fn problems(root: &Path) -> Vec<String> {
    [bend_problem(root), bun_problem(root)]
        .into_iter()
        .flatten()
        .collect()
}
