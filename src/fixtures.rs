//! Run every fixture case against its rule and check the expectations.
//!
//!   blr test                    all cases
//!   blr test dead/def           the cases of one rule
//!   blr test dead/def/pass_x    one case
//!
//! A case is a folder fixtures/<group>/<rule>/<case>/ with
//!   main.bend         the file linted (the entry file; it may import siblings)
//!   bend-lint.json    options and severity for the rule (the case's own, never a parent's)
//!   rule              optional: the rule file, as a path from the repo root, when it is not
//!                     rules/<group>/<rule>.bend
//!   expect            one expectation per line:
//!                       exit N          bend-lint's exit code
//!                       findings N      the number of diagnostics printed
//!                       contains TEXT   TEXT appears in the output (fixed string)
//!                       lacks TEXT      TEXT does not appear in the output
//!                     blank lines and lines starting with # are ignored
use crate::proc::{bun, lint_ts, run, text, Ran};
use std::fs;
use std::io;
use std::path::{Path, PathBuf};
use std::thread;

#[derive(Debug, PartialEq)]
pub enum Expect {
    Exit(i32),
    Findings(usize),
    Contains(String),
    Lacks(String),
    Bad(String),
}

pub fn parse_expect(text: &str) -> Vec<Expect> {
    text.lines()
        .filter(|l| !l.trim().is_empty() && !l.starts_with('#'))
        .map(|line| match line.split_once(' ') {
            Some(("exit", n)) => n
                .trim()
                .parse()
                .map_or_else(|_| Expect::Bad(line.to_string()), Expect::Exit),
            Some(("findings", n)) => n
                .trim()
                .parse()
                .map_or_else(|_| Expect::Bad(line.to_string()), Expect::Findings),
            Some(("contains", t)) => Expect::Contains(t.to_string()),
            Some(("lacks", t)) => Expect::Lacks(t.to_string()),
            _ => Expect::Bad(line.to_string()),
        })
        .collect()
}

/// The diagnostics bend-lint printed: lines that open one (`Warning [rule]:`).
pub fn count_findings(out: &str) -> usize {
    out.lines()
        .filter(|l| {
            ["Error [", "Warning [", "Information [", "Hint ["]
                .iter()
                .any(|p| l.starts_with(p))
        })
        .count()
}

/// Why the run does not meet the expectation, if it does not.
pub fn problem(expect: &Expect, ran: &Ran) -> Option<String> {
    match expect {
        Expect::Exit(n) => (ran.code != *n).then(|| format!("exit: want {n}, got {}", ran.code)),
        Expect::Findings(n) => {
            let got = count_findings(&ran.out);
            (got != *n).then(|| format!("findings: want {n}, got {got}"))
        }
        Expect::Contains(t) => (!ran.out.contains(t.as_str())).then(|| format!("missing: {t}")),
        Expect::Lacks(t) => ran
            .out
            .contains(t.as_str())
            .then(|| format!("unexpected: {t}")),
        Expect::Bad(line) => Some(format!("bad expectation: {line}")),
    }
}

/// The folders under `dir` that hold an `expect` file, sorted.
fn case_dirs(dir: &Path) -> io::Result<Vec<PathBuf>> {
    let mut entries = fs::read_dir(dir)?
        .map(|e| e.map(|e| e.path()))
        .collect::<io::Result<Vec<_>>>()?;
    entries.sort();
    let nested = entries
        .iter()
        .filter(|p| p.is_dir())
        .map(|p| case_dirs(p))
        .collect::<io::Result<Vec<_>>>()?;
    let here = entries
        .iter()
        .any(|p| p.file_name().is_some_and(|n| n == "expect"));
    Ok(here
        .then(|| dir.to_path_buf())
        .into_iter()
        .chain(nested.into_iter().flatten())
        .collect())
}

fn rule_for(root: &Path, fixtures: &Path, dir: &Path) -> PathBuf {
    match fs::read_to_string(dir.join("rule")) {
        Ok(over) => root.join(over.trim()),
        Err(_) => {
            let rule = dir
                .parent()
                .and_then(|p| p.strip_prefix(fixtures).ok())
                .unwrap_or(dir);
            root.join("rules").join(format!("{}.bend", rule.display()))
        }
    }
}

pub struct Verdict {
    pub name: String,
    pub problems: Vec<String>,
    pub out: String,
}

fn run_case(root: &Path, fixtures: &Path, dir: &Path) -> Verdict {
    let name = dir
        .strip_prefix(fixtures)
        .unwrap_or(dir)
        .display()
        .to_string();
    let args = vec![
        text(&lint_ts(root)),
        "main.bend".to_string(),
        "--rules".to_string(),
        text(&rule_for(root, fixtures, dir)),
    ];
    let ran = run(&bun(), &args, dir).unwrap_or_else(|e| Ran {
        code: 127,
        out: format!("cannot run bun: {e}"),
    });
    let expect = fs::read_to_string(dir.join("expect")).unwrap_or_default();
    Verdict {
        name,
        problems: parse_expect(&expect)
            .iter()
            .filter_map(|e| problem(e, &ran))
            .collect(),
        out: ran.out,
    }
}

fn show(v: &Verdict) {
    println!(
        "{} {}",
        if v.problems.is_empty() {
            "ok  "
        } else {
            "FAIL"
        },
        v.name
    );
    if !v.problems.is_empty() {
        v.problems.iter().for_each(|p| println!("    {p}"));
        v.out.lines().for_each(|l| println!("    | {l}"));
    }
}

/// Runs the cases whose name starts with `filter`, a few at a time; whether all pass (and some ran).
pub fn run_all(root: &Path, filter: &str) -> io::Result<bool> {
    let fixtures = root.join("fixtures");
    let dirs: Vec<PathBuf> = case_dirs(&fixtures)?
        .into_iter()
        .filter(|d| {
            d.strip_prefix(&fixtures)
                .is_ok_and(|n| n.to_string_lossy().starts_with(filter))
        })
        .collect();
    let width = thread::available_parallelism().map_or(2, |n| n.get());
    let verdicts: Vec<Verdict> = dirs
        .chunks(width)
        .flat_map(|chunk| {
            thread::scope(|s| {
                let handles: Vec<_> = chunk
                    .iter()
                    .map(|d| s.spawn(|| run_case(root, &fixtures, d)))
                    .collect();
                handles
                    .into_iter()
                    .map(|h| h.join().expect("a case thread panicked"))
                    .collect::<Vec<_>>()
            })
        })
        .collect();
    verdicts.iter().for_each(show);
    let failed = verdicts.iter().filter(|v| !v.problems.is_empty()).count();
    println!("\n{} passed; {failed} failed", verdicts.len() - failed);
    Ok(failed == 0 && !verdicts.is_empty())
}
