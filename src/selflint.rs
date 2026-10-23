//! Lint this repo's own rules with the pack: every rule file must come out with no findings.
//! common.bend is a library (no main), so every def in it is an entry (rules/common.bend-lint.json).
use crate::lint;
use crate::proc::text;
use std::io;
use std::path::{Path, PathBuf};

fn targets(root: &Path) -> io::Result<Vec<(PathBuf, Vec<String>)>> {
    let common = root.join("rules/common.bend");
    let library = vec![
        "--config".to_string(),
        text(&root.join("rules/common.bend-lint.json")),
    ];
    Ok(lint::rule_files(root)?
        .into_iter()
        .map(|file| (file, Vec::new()))
        .chain([(common, library)])
        .collect())
}

fn clean(root: &Path, file: &Path, flags: &[String]) -> io::Result<bool> {
    let args: Vec<String> = [text(file)]
        .into_iter()
        .chain(flags.iter().cloned())
        .collect();
    let ran = lint::capture(root, &args)?;
    let ok = ran.code == 0 && ran.out.contains("bend-lint: 0 finding(s)");
    let name = file.strip_prefix(root).unwrap_or(file).display();
    println!("{} {name}", if ok { "ok  " } else { "FAIL" });
    if !ok {
        ran.out.lines().for_each(|line| println!("    | {line}"));
    }
    Ok(ok)
}

/// Whether every target is clean.
pub fn run_all(root: &Path) -> io::Result<bool> {
    let results = targets(root)?
        .iter()
        .map(|(file, flags)| clean(root, file, flags))
        .collect::<io::Result<Vec<_>>>()?;
    Ok(results.into_iter().all(|ok| ok))
}
