# graph/fan_in: warn when more than `max` different defs of the program use one def (default 20).
#
# Fan-in is a def's weight: every caller depends on its contract, so a change to it spreads.
# Counted: the different defs, in the linted file and the files it imports, that reference the def
# (in their bodies or types). Not counted: itself, laws and their proofs (specs, not callers), Base,
# hub packages. By default only the linted file's own defs are reported (`imports` reports every
# local file of the program). Lint the entry file so that callers in imported files are seen.
# Options: max (default 20), imports (default false).
import Base
import ../vendor/lint.bend as Lint
import ../common.bend as Common

def id() -> String:
  "graph/fan_in"

def facts() -> Lint.Want:
  Lint.Want{Lint.Program{}, [], [], []}

def message(+name: String, d: U32, max: U32) -> String:
  "def " ++ name ++ " is used by " ++ U32.show(d) ++ " different defs; the limit is " ++ U32.show(max) ++ ". Keep its contract small and stable, or split it by purpose."

def judge.one(+d: U32, +max: U32, +owner: String, span: Maybe<&2, Lint.Span>) -> List<&2, Lint.Diag>:
  Common.when(
    U32.is_gt(d, max),
    Common.diag(Lint.Warning{}, message(owner, d, max), span)
  )

def judge(
  seen: List<&2, Common.Seen>,
  +max: U32,
  +nodes: Set(),
  +into: Map<&2, List<&2, String>>,
  out: List<&2, Lint.Diag>
) -> List<&2, Lint.Diag>:
  match seen:
    case Nil{}:
      List.reverse(&2, Lint.Diag, out)
    case Con{Common.Seen{+owner, span}, rest}:
      judge(
        rest,
        max,
        nodes,
        into,
        Common.onto(
          judge.one(Common.degree(into, nodes, owner), max, owner, span),
          out
        )
      )

def verdict(p: Common.Prog, max: U32, scope: Common.Scope) -> List<&2, Lint.Diag>:
  match p:
    case Common.Prog{seen, edges, into, nodes, laws}:
      judge(Common.scoped(scope, seen), max, nodes, into, [])

def run(input: Lint.Input) -> IO(List<&2, Lint.Diag>):
  match input:
    case Lint.Input{+sources, +options}:
      do IO<List<&2, Lint.Diag>>:
        g : Common.Graph <- Lint.fold_facts(~Common.Graph, ~Common.Graph.collect, Common.Graph.empty())
        p : Common.Prog <- Common.Prog.of(sources, g)
        return verdict(p, Lint.option_number(options, "max", 20), Common.Scope.of(sources, options))

def main() -> IO(Unit):
  Lint.serve(run)
