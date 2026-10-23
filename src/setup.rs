//! Fetch the pinned bendlang/bend checkout that holds tools/bend-lint (the linter) and
//! src/bend/lint.bend (the rule API every rule here imports). Idempotent: a checkout already at the
//! pinned commit is left alone. The pin is upstream.env.
use crate::proc::{run, strs, text, Ran};
use std::collections::HashMap;
use std::fs;
use std::io;
use std::path::Path;

pub struct Pin {
    pub url: String,
    pub tag: String,
    pub commit: String,
}

/// `KEY=value` lines (blank lines and `#` comments skipped), as in upstream.env.
pub fn parse_pin(text: &str) -> Result<Pin, String> {
    let pairs: HashMap<&str, &str> = text
        .lines()
        .map(str::trim)
        .filter(|l| !l.is_empty() && !l.starts_with('#'))
        .filter_map(|l| l.split_once('='))
        .collect();
    let get = |key: &str| {
        pairs
            .get(key)
            .map(|v| (*v).to_string())
            .ok_or_else(|| format!("upstream.env: {key} is missing"))
    };
    Ok(Pin {
        url: get("UPSTREAM_URL")?,
        tag: get("UPSTREAM_TAG")?,
        commit: get("UPSTREAM_COMMIT")?,
    })
}

fn must(what: &str, ran: io::Result<Ran>) -> Result<String, String> {
    let ran = ran.map_err(|e| format!("{what}: {e}"))?;
    if ran.code == 0 {
        Ok(ran.out.trim().to_string())
    } else {
        Err(format!("{what} failed (exit {}):\n{}", ran.code, ran.out))
    }
}

fn head(dest: &Path) -> Option<String> {
    dest.join(".git").exists().then_some(())?;
    let args = vec![
        "-C".to_string(),
        text(dest),
        "rev-parse".to_string(),
        "HEAD".to_string(),
    ];
    must("git rev-parse", run("git", &args, dest)).ok()
}

fn fetch(root: &Path, dest: &Path, pin: &Pin) -> Result<(), String> {
    let at = text(dest);
    if dest.join(".git").exists() {
        let spec = format!("refs/tags/{0}:refs/tags/{0}", pin.tag);
        let fetch = vec![
            "-C".to_string(),
            at.clone(),
            "fetch".to_string(),
            "--quiet".to_string(),
            "--depth".to_string(),
            "1".to_string(),
            "origin".to_string(),
            spec,
        ];
        must("git fetch", run("git", &fetch, root))?;
        let checkout = vec![
            "-C".to_string(),
            at,
            "-c".to_string(),
            "advice.detachedHead=false".to_string(),
            "checkout".to_string(),
            "--quiet".to_string(),
            "--detach".to_string(),
            pin.tag.clone(),
        ];
        must("git checkout", run("git", &checkout, root)).map(|_| ())
    } else {
        let mut clone = strs([
            "-c",
            "advice.detachedHead=false",
            "clone",
            "--quiet",
            "--depth",
            "1",
            "--branch",
        ]);
        clone.extend([pin.tag.clone(), pin.url.clone(), at]);
        must("git clone", run("git", &clone, root)).map(|_| ())
    }
}

/// Makes the checkout match upstream.env, or says why not; says what it did.
pub fn ensure(root: &Path) -> Result<String, String> {
    let pin = parse_pin(
        &fs::read_to_string(root.join("upstream.env")).map_err(|e| format!("upstream.env: {e}"))?,
    )?;
    let dest = crate::proc::upstream_dir(root);
    if head(&dest).as_deref() == Some(pin.commit.as_str()) {
        return Ok(format!("upstream: {} at {} (ok)", pin.tag, pin.commit));
    }
    fs::create_dir_all(root.join("upstream")).map_err(|e| format!("upstream: {e}"))?;
    fetch(root, &dest, &pin)?;
    match head(&dest) {
        Some(h) if h == pin.commit => {
            Ok(format!("upstream: {} at {} (fetched)", pin.tag, pin.commit))
        }
        other => Err(format!(
            "upstream: {} is {}, expected {} (the upstream tag moved?)",
            pin.tag,
            other.unwrap_or_else(|| "missing".to_string()),
            pin.commit
        )),
    }
}
