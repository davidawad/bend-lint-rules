# dead/def: warn about a def that no entry point reaches.
#
# Entry points: `main`, every law and the def that proves it (laws are specs, so what they mention
# is live), and the names in the `entries` option. Everything reachable from an entry through
# references (in bodies and in types) is live; every other def is dead, so a chain of defs that
# only call each other is reported whole. Self-references do not count.
#
# Bend has no export keyword, so a def meant for outside callers (a library API, a def a JS host
# calls) is named in `entries`: a comma-separated list of names, where `name*` is a prefix and a
# name matches with or without its file's namespace (`helper` or `util:helper`). `*` alone makes
# every def an entry.
#
# The program is the linted file and what it imports, so lint the entry file. By default only the
# linted file's own defs are reported; `imports` reports the defs of every local file of the program
# (set it when the imports are your own modules and the linted file is the whole application).
# Not reported: types and constructors, foreign effect defs (they have no checked body), and hub
# packages. With no `main`, no law and no `entries`, there is nothing to measure from: one hint
# says so.
# Options: entries (default ""), imports (default false).
import Base
import ../../upstream/bend/tools/bend-lint/src/bend/lint.bend as Lint
import ../common.bend as Common

def id() -> String:
  "dead/def"

def facts() -> Lint.Want:
  Lint.Want{Lint.Program{}, [], [], []}

# Entry points
# ============
def is_root(+laws: Set(), +entries: List<&2, String>, +owner: String) -> Bool:
  Bool.or(
    String.eq(owner, "main"),
    Bool.or(Common.Laws.has(laws, owner), Common.Entry.any(entries, owner))
  )

def roots(
  seen: List<&2, Common.Seen>,
  +laws: Set(),
  +entries: List<&2, String>,
  +out: List<&2, String>
) -> List<&2, String>:
  match seen:
    case Nil{}:
      out
    case Con{Common.Seen{+owner, span}, rest}:
      roots(
        rest,
        laws,
        entries,
        Bool.pick(List<&2, String>, is_root(laws, entries, owner), owner <> out, out)
      )

# Reachability
# ============
# The names reachable from `work` through `edges`. Each name is expanded once, and the names are
# finite, so this terminates; Bend cannot see that, hence @unsafe.
@unsafe
def reach(work: List<&2, String>, +edges: Map<&2, List<&2, String>>, +seen: Set()) -> Set():
  match work:
    case Nil{}:
      seen
    case Con{+name, rest}:
      reach.go(Common.has(seen, name), name, rest, edges, seen)

def reach.go(
  known: Bool,
  +name: String,
  rest: List<&2, String>,
  +edges: Map<&2, List<&2, String>>,
  +seen: Set()
) -> Set():
  match known:
    case True{}:
      reach(rest, edges, seen)
    case False{}:
      reach(
        List.append(&2, String, Common.Edges.of(edges, name), rest),
        edges,
        Set.add(seen, name)
      )

# Findings
# ========
def message(+owner: String, referenced: Bool) -> String:
  Bool.pick(
    String,
    referenced,
    "def " ++ owner ++ " is dead: only dead defs use it. Delete it, or name it in the `entries` option if code outside this program calls it.",
    "def " ++ owner ++ " is never referenced. Delete it, or name it in the `entries` option if code outside this program calls it."
  )

def is_dead(+nodes: Set(), +reached: Set(), +owner: String) -> Bool:
  Bool.and(Common.has(nodes, owner), Bool.not(Common.has(reached, owner)))

def report(
  seen: List<&2, Common.Seen>,
  +nodes: Set(),
  +reached: Set(),
  +into: Map<&2, List<&2, String>>,
  out: List<&2, Lint.Diag>
) -> List<&2, Lint.Diag>:
  match seen:
    case Nil{}:
      out
    case Con{Common.Seen{+owner, span}, rest}:
      report(
        rest,
        nodes,
        reached,
        into,
        Common.onto(
          Common.when(
            is_dead(nodes, reached, owner),
            Common.diag(
              Lint.Warning{},
              message(
                owner,
                Bool.not(List.is_empty(&2, String, Common.Edges.of(into, owner)))
              ),
              span
            )
          ),
          out
        )
      )

def nothing() -> Lint.Diag:
  Common.diag(
    Lint.Hint{},
    "dead/def has nothing to measure from: the program has no `main`, no law and no `entries` option. Lint the entry file, or set `entries`.",
    None{}
  )

# `none`: there is no entry point. `shown`: the owners reported on.
def verdict.go(
  none: Bool,
  +rs: List<&2, String>,
  shown: List<&2, Common.Seen>,
  nodes: Set(),
  +edges: Map<&2, List<&2, String>>,
  into: Map<&2, List<&2, String>>
) -> List<&2, Lint.Diag>:
  match none:
    case True{}:
      [nothing()]
    case False{}:
      List.reverse(
        &2,
        Lint.Diag,
        report(shown, nodes, reach(rs, edges, Set.new()), into, [])
      )

def verdict.roots(
  +rs: List<&2, String>,
  shown: List<&2, Common.Seen>,
  nodes: Set(),
  edges: Map<&2, List<&2, String>>,
  into: Map<&2, List<&2, String>>
) -> List<&2, Lint.Diag>:
  verdict.go(List.is_empty(&2, String, rs), rs, shown, nodes, edges, into)

def verdict.laws(
  +laws: Set(),
  entries: String,
  +seen: List<&2, Common.Seen>,
  scope: Common.Scope,
  nodes: Set(),
  edges: Map<&2, List<&2, String>>,
  into: Map<&2, List<&2, String>>
) -> List<&2, Lint.Diag>:
  verdict.roots(
    roots(seen, laws, Common.Entry.parse(entries), []),
    Common.scoped(scope, seen),
    nodes,
    edges,
    into
  )

def verdict(p: Common.Prog, entries: String, scope: Common.Scope) -> List<&2, Lint.Diag>:
  match p:
    case Common.Prog{seen, edges, into, nodes, laws}:
      verdict.laws(laws, entries, seen, scope, nodes, edges, into)

def run(input: Lint.Input) -> IO(List<&2, Lint.Diag>):
  match input:
    case Lint.Input{+sources, +options}:
      do IO<List<&2, Lint.Diag>>:
        g : Common.Graph <- Lint.fold_facts(~Common.Graph, ~Common.Graph.collect, Common.Graph.empty())
        p : Common.Prog <- Common.Prog.of(sources, g)
        return verdict(
          p,
          Lint.option_text(options, "entries", ""),
          Common.Scope.of(sources, options)
        )

def main() -> IO(Unit):
  Lint.serve(run)
