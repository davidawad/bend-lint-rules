//! Lint one Bend file with this pack: the rules in rules/ plus upstream's style/file-length.
//!
//!   blr lint path/to/main.bend [bend-lint flags]     e.g. --json, --config file.json
//!
//! Lint the program's entry file: the program is that file and what it imports. The nearest
//! bend-lint.json above the file sets options and severity (see bend-lint.json in this repo for the
//! defaults); `--config` names another.
use crate::proc::{bun, file_length_rule, lint_ts, run, text, Ran};
use std::fs;
use std::io;
use std::path::{Path, PathBuf};
use std::process::Command;

fn sorted(dir: &Path, keep: impl Fn(&Path) -> bool) -> io::Result<Vec<PathBuf>> {
    let mut paths = fs::read_dir(dir)?
        .map(|entry| entry.map(|e| e.path()))
        .collect::<io::Result<Vec<_>>>()?;
    paths.retain(|p| keep(p));
    paths.sort();
    Ok(paths)
}

/// The rule files of this pack in order: rules/<group>/<name>.bend.
pub fn rule_files(root: &Path) -> io::Result<Vec<PathBuf>> {
    let groups = sorted(&root.join("rules"), |p| {
        p.is_dir() && p.file_name().is_some_and(|n| n != "vendor")
    })?;
    let per_group = groups
        .iter()
        .map(|group| sorted(group, |p| p.extension().is_some_and(|e| e == "bend")))
        .collect::<io::Result<Vec<_>>>()?;
    Ok(per_group.into_iter().flatten().collect())
}

/// bend-lint's command line: the user's arguments, then every rule of the pack.
pub fn command_args(root: &Path, user: &[String]) -> io::Result<Vec<String>> {
    let rules = rule_files(root)?
        .into_iter()
        .chain([file_length_rule(root)])
        .flat_map(|rule| ["--rules".to_string(), text(&rule)]);
    Ok([text(&lint_ts(root))]
        .into_iter()
        .chain(user.iter().cloned())
        .chain(rules)
        .collect())
}

/// Runs the pack, printing as bend-lint does; its exit code.
pub fn exec(root: &Path, user: &[String]) -> io::Result<i32> {
    let args = command_args(root, user)?;
    let status = Command::new(bun()).args(&args).status()?;
    Ok(status.code().unwrap_or(2))
}

/// Runs the pack and keeps what it printed.
pub fn capture(root: &Path, user: &[String]) -> io::Result<Ran> {
    run(&bun(), &command_args(root, user)?, root)
}
