# complexity/cyclomatic: warn when a def has more than `max` independent paths (default 10).
#
# Bend has no loops or `if`; every branch is a `match`. Bend checks a match into one Mat node per
# tested constructor, closed by an Efq node when the arms are exhaustive. The closing test is not a
# decision (its failure is impossible), so
#
#   complexity = 1 + (Mat nodes - Efq nodes)
#
# Three arms give 3; two arms and a `_` give 2 + 1 = 3; a single-constructor destructuring gives 1.
# A match on several values at once (`match a b:`) is checked as nested tests and counts as such.
# Options: max (default 10).
import Base
import ../../upstream/bend/tools/bend-lint/src/bend/lint.bend as Lint
import ../common.bend as Common

def id() -> String:
  "complexity/cyclomatic"

def facts() -> Lint.Want:
  Lint.Want{Lint.File{}, [], [], []}

# Node kinds seen under a def.
type Tally is Data:
  Tally{mats: U32, efqs: U32}

def bump.kind(+kind: String, t: Tally) -> Tally:
  match t:
    case Tally{+mats, +efqs}:
      Bool.pick(
        Tally,
        String.eq(kind, "Mat"),
        Tally{U32.add(mats, 1), efqs},
        Bool.pick(
          Tally,
          String.eq(kind, "Efq"),
          Tally{mats, U32.add(efqs, 1)},
          Tally{mats, efqs}
        )
      )

# The checked body is a finite tree, so this terminates; Bend cannot see that (nodes are handles, not
# smaller parts), hence @unsafe, as bend-lint's own fold_facts.
@unsafe
def walk(n: Lint.Node, t: Tally) -> IO(Tally):
  do IO<Tally>:
    s : Lint.Shape <- Lint.shape(n)
    walk.shape(s, t)

def walk.all(cs: List<&2, Lint.Node>, t: Tally) -> IO(Tally):
  match cs:
    case Nil{}:
      IO.pure(Tally, t)
    case Con{c, rest}:
      IO.bind(Tally, Tally, walk(c, t), t2 => walk.all(rest, t2))

def walk.shape(s: Lint.Shape, t: Tally) -> IO(Tally):
  match s:
    case Lint.Shape{kind, name, span, children}:
      walk.all(children, bump.kind(kind, t))

# 1 + Mat - Efq; never below 1.
def complexity(t: Tally) -> U32:
  match t:
    case Tally{+mats, efqs}:
      U32.add(1, U32.sub(mats, U32.min(mats, efqs)))

def score.of(body: Maybe<&2, Lint.Node>) -> IO(U32):
  match body:
    case None{}:
      IO.pure(U32, 0)
    case Some{n}:
      IO.bind(Tally, U32, walk(n, Tally{0, 0}), t => IO.pure(U32, complexity(t)))

def message(+name: String, score: U32, max: U32) -> String:
  "def " ++ name ++ " has cyclomatic complexity " ++ U32.show(score) ++ "; the limit is " ++ U32.show(max) ++ ". Split it into smaller defs."

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
        judge(Lint.option_number(options, "max", 10), Common.Owners.ordered(owners), [])

def main() -> IO(Unit):
  Lint.serve(run)
