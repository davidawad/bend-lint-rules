//! Running other programs, and the paths of this repo.
use std::io;
use std::path::{Path, PathBuf};
use std::process::{Command, Stdio};

/// A finished process: its exit code and its output, stdout then stderr.
#[derive(Debug)]
pub struct Ran {
    pub code: i32,
    pub out: String,
}

pub fn run(cmd: &str, args: &[String], cwd: &Path) -> io::Result<Ran> {
    let output = Command::new(cmd)
        .args(args)
        .current_dir(cwd)
        .stdin(Stdio::null())
        .output()?;
    Ok(Ran {
        code: output.status.code().unwrap_or(1),
        out: format!(
            "{}{}",
            String::from_utf8_lossy(&output.stdout),
            String::from_utf8_lossy(&output.stderr)
        ),
    })
}

/// Arguments as owned strings.
pub fn strs<const N: usize>(xs: [&str; N]) -> Vec<String> {
    xs.iter().map(|x| (*x).to_string()).collect()
}

pub fn text(path: &Path) -> String {
    path.to_string_lossy().into_owned()
}

/// The Bun to run bend-lint with: `$BUN`, else `bun` on PATH.
pub fn bun() -> String {
    std::env::var("BUN").unwrap_or_else(|_| "bun".to_string())
}

/// The root of this repo: the folder of Cargo.toml.
pub fn root() -> PathBuf {
    PathBuf::from(env!("CARGO_MANIFEST_DIR"))
}

pub fn upstream_dir(root: &Path) -> PathBuf {
    root.join("upstream").join("bend")
}

/// The linter, in the upstream checkout.
pub fn lint_ts(root: &Path) -> PathBuf {
    upstream_dir(root).join("tools/bend-lint/src/lint.ts")
}

/// Upstream's own `style/file-length` rule.
pub fn file_length_rule(root: &Path) -> PathBuf {
    upstream_dir(root).join("tools/bend-lint/rules/file_length.bend")
}
