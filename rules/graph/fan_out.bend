# graph/fan_out: warn when a def uses more than `max` different defs of the program (default 10).
#
# Fan-out is a def's coupling: each def it calls or names in a type is something it breaks with.
# Counted: the different defs, in the linted file and the files it imports, that the def references
# (in its body or its types). Not counted: itself, Base, hub packages, types, constructors, laws.
# By default only the linted file's own defs are reported (`imports` reports every local file of
# the program). Lint the entry file so that defs in imported files are seen.
# Options: max (default 10), imports (default false).
import Base
import ../../upstream/bend/tools/bend-lint/src/bend/lint.bend as Lint
import ../common.bend as Common

def id() -> String:
  "graph/fan_out"

def facts() -> Lint.Want:
  Lint.Want{Lint.Program{}, [], [], []}

def message(+name: String, d: U32, max: U32) -> String:
  "def " ++ name ++ " uses " ++ U32.show(d) ++ " different defs; the limit is " ++ U32.show(max) ++ ". Group related calls behind a helper def."

def judge.one(+d: U32, +max: U32, +owner: String, span: Maybe<&2, Lint.Span>) -> List<&2, Lint.Diag>:
  Common.when(
    U32.is_gt(d, max),
    Common.diag(Lint.Warning{}, message(owner, d, max), span)
  )

def judge(
  seen: List<&2, Common.Seen>,
  +max: U32,
  +nodes: Set(),
  +edges: Map<&2, List<&2, String>>,
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
        edges,
        Common.onto(
          judge.one(Common.degree(edges, nodes, owner), max, owner, span),
          out
        )
      )

def verdict(p: Common.Prog, max: U32, scope: Common.Scope) -> List<&2, Lint.Diag>:
  match p:
    case Common.Prog{seen, edges, into, nodes, laws}:
      judge(Common.scoped(scope, seen), max, nodes, edges, [])

def run(input: Lint.Input) -> IO(List<&2, Lint.Diag>):
  match input:
    case Lint.Input{+sources, +options}:
      do IO<List<&2, Lint.Diag>>:
        g : Common.Graph <- Lint.fold_facts(~Common.Graph, ~Common.Graph.collect, Common.Graph.empty())
        p : Common.Prog <- Common.Prog.of(sources, g)
        return verdict(p, Lint.option_number(options, "max", 10), Common.Scope.of(sources, options))

def main() -> IO(Unit):
  Lint.serve(run)
