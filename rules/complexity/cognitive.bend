# complexity/cognitive: warn when a def is harder to read than `max` (default 15).
#
# Nesting-weighted, after SonarSource's cognitive complexity, with Bend's only branch, `match`:
# each match adds 1, plus 1 for every match it sits inside (an arm body of an outer match).
# Arms of one match do not nest in each other.
#
# Bend checks a match into a chain of Mat nodes, one per tested constructor: a Mat's first child is
# the arm body, and its second is the rest of the chain (another Mat) or the `_` arm (a Lam).
# This rule walks that tree and starts a match only at a Mat that is not the rest of a chain.
# A match on several values at once (`match a b:`) is checked as nested tests and counts as such.
# Options: max (default 15).
import Base
import ../vendor/lint.bend as Lint
import ../common.bend as Common

def id() -> String:
  "complexity/cognitive"

def facts() -> Lint.Want:
  Lint.Want{Lint.File{}, [], [], []}

# The tree walk. `depth` is the number of matches around the node, `chain` says the node is the
# rest of a match chain (reached from its Mat), and `total` is the score so far.
# The checked body is a finite tree, so this terminates; Bend cannot see that (nodes are handles,
# not smaller parts), hence @unsafe, as bend-lint's own fold_facts.
@unsafe
def walk(n: Lint.Node, depth: U32, chain: Bool, total: U32) -> IO(U32):
  do IO<U32>:
    s : Lint.Shape <- Lint.shape(n)
    walk.shape(s, depth, chain, total)

# Each of `cs` the same way.
def walk.all(cs: List<&2, Lint.Node>, +depth: U32, +chain: Bool, total: U32) -> IO(U32):
  match cs:
    case Nil{}:
      IO.pure(U32, total)
    case Con{c, rest}:
      IO.bind(U32, U32, walk(c, depth, chain, total), t2 => walk.all(rest, depth, chain, t2))

# The children of a Mat: the first is an arm body, one level down; the others continue the chain.
def walk.arms(cs: List<&2, Lint.Node>, +depth: U32, +first: Bool, total: U32) -> IO(U32):
  match cs:
    case Nil{}:
      IO.pure(U32, total)
    case Con{c, rest}:
      IO.bind(
        U32,
        U32,
        walk(c, Bool.pick(U32, first, U32.add(depth, 1), depth), Bool.not(first), total),
        t2 => walk.arms(rest, depth, False{}, t2)
      )

def walk.step(
  is_mat: Bool,
  is_ann: Bool,
  children: List<&2, Lint.Node>,
  +depth: U32,
  +chain: Bool,
  total: U32
) -> IO(U32):
  match is_mat is_ann:
    case True{} _:
      walk.arms(
        children,
        depth,
        True{},
        U32.add(total, Bool.pick(U32, chain, 0, U32.add(depth, 1)))
      )
    case False{} True{}:
      walk.all(children, depth, chain, total)
    case False{} False{}:
      walk.all(children, Bool.pick(U32, chain, U32.add(depth, 1), depth), False{}, total)

def walk.shape(s: Lint.Shape, depth: U32, chain: Bool, total: U32) -> IO(U32):
  match s:
    case Lint.Shape{+kind, name, span, children}:
      walk.step(String.eq(kind, "Mat"), String.eq(kind, "Ann"), children, depth, chain, total)

def score.of(body: Maybe<&2, Lint.Node>) -> IO(U32):
  match body:
    case None{}:
      IO.pure(U32, 0)
    case Some{n}:
      walk(n, 0, False{}, 0)

def message(+name: String, score: U32, max: U32) -> String:
  "def " ++ name ++ " has cognitive complexity " ++ U32.show(score) ++ "; the limit is " ++ U32.show(max) ++ ". Flatten nested matches into helper defs."

def judge(+max: U32, seen: List<&2, Common.Seen>, out: List<&2, Lint.Diag>) -> IO(List<&2, Lint.Diag>):
  match seen:
    case Nil{}:
      IO.pure(List<&2, Lint.Diag>, List.reverse(&2, Lint.Diag, out))
    case Con{Common.Seen{+owner, span}, rest}:
      do IO<List<&2, Lint.Diag>>:
        body : Maybe<&2, Lint.Node> <- Lint.body(owner)
        +score : U32 <- score.of(body)
        judge(
          max,
          rest,
          Common.onto(
            Common.when(
              U32.is_gt(score, max),
              Common.diag(Lint.Warning{}, message(owner, score, max), span)
            ),
            out
          )
        )

def run(input: Lint.Input) -> IO(List<&2, Lint.Diag>):
  match input:
    case Lint.Input{sources, options}:
      do IO<List<&2, Lint.Diag>>:
        owners : Common.Owners <- Lint.fold_facts(~Common.Owners, ~Common.Owners.collect, Common.Owners.empty())
        judge(Lint.option_number(options, "max", 15), Common.Owners.ordered(owners), [])

def main() -> IO(Unit):
  Lint.serve(run)
