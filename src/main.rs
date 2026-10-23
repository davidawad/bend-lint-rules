//! `blr`: setup, version pins, fixture runner and lint wrapper for this repo's Bend rules.
//!
//!   blr setup               fetch the pinned upstream bend-lint checkout
//!   blr check-versions      bend and bun are the pinned versions
//!   blr test [filter]       run the fixture cases
//!   blr self                lint this repo's own rules with the pack
//!   blr lint FILE [flags]   lint a Bend file with the pack
mod fixtures;
mod lint;
mod proc;
mod selflint;
mod setup;
mod versions;

use std::process::ExitCode;

fn exit(ok: bool) -> ExitCode {
    if ok {
        ExitCode::SUCCESS
    } else {
        ExitCode::FAILURE
    }
}

fn report<T>(result: Result<T, String>, then: impl FnOnce(T) -> ExitCode) -> ExitCode {
    result.map_or_else(
        |message| {
            eprintln!("{message}");
            ExitCode::FAILURE
        },
        then,
    )
}

fn io_failure(e: std::io::Error) -> ExitCode {
    eprintln!("blr: {e}");
    ExitCode::from(2)
}

fn main() -> ExitCode {
    let root = proc::root();
    let args: Vec<String> = std::env::args().skip(1).collect();
    match args.first().map(String::as_str) {
        Some("setup") => report(setup::ensure(&root), |said| {
            println!("{said}");
            ExitCode::SUCCESS
        }),
        Some("check-versions") => {
            let problems = versions::problems(&root);
            problems.iter().for_each(|p| eprintln!("versions: {p}"));
            if problems.is_empty() {
                println!("versions: bend pinned, bun new enough (ok)");
            }
            exit(problems.is_empty())
        }
        Some("test") => report(setup::ensure(&root), |said| {
            println!("{said}");
            let filter = args.get(1).map_or("", String::as_str);
            fixtures::run_all(&root, filter).map_or_else(io_failure, exit)
        }),
        Some("self") => report(setup::ensure(&root), |_| {
            selflint::run_all(&root).map_or_else(io_failure, exit)
        }),
        Some("lint") => report(setup::ensure(&root), |_| {
            lint::exec(&root, &args[1..]).map_or_else(io_failure, |code| {
                ExitCode::from(u8::try_from(code).unwrap_or(2))
            })
        }),
        _ => {
            eprintln!(
                "usage: blr setup | check-versions | test [filter] | self | lint FILE [flags]"
            );
            ExitCode::from(2)
        }
    }
}
