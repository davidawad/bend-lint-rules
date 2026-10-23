# Helpers shared by the rules in this repo. A rule file imports this as ../common.bend.
import Base
import ../upstream/bend/tools/bend-lint/src/bend/lint.bend as Lint

# Owners of facts
# ===============
# A global name that owns facts (a def, a law, a type, a constructor), and where its first fact sits.
type Seen is Data:
  Seen{owner: String, span: Maybe<&2, Lint.Span>}

# The owners of the facts read so far: in reverse order of first appearance, and as a set.
type Owners is Data:
  Owners{list: List<&2, Seen>, set: Set()}

def Owners.empty() -> Owners:
  Owners{[], Set.new()}

def Owners.pick(
  list: List<&2, Seen>,
  +set: Set(),
  had: Bool,
  +owner: String,
  inst: Bool,
  span: Maybe<&2, Lint.Span>
) -> Owners:
  match had inst:
    case False{} False{}:
      Owners{Seen{owner, span} <> list, Set.add(set, owner)}
    case _ _:
      Owners{list, set}

def Owners.seen(
  list: List<&2, Seen>,
  r: Set() & Bool,
  +owner: String,
  inst: Bool,
  span: Maybe<&2, Lint.Span>
) -> Owners:
  match r:
    case Tuple{set, had}:
      Owners.pick(list, set, had, owner, inst, span)

# Template instances are skipped, so a template is seen once, as itself.
def Owners.note(acc: Owners, +owner: String, inst: Bool, span: Maybe<&2, Lint.Span>) -> Owners:
  match acc:
    case Owners{list, +set}:
      Owners.seen(list, Set.has(set, owner), owner, inst, span)

def Owners.add(acc: Owners, v: Lint.View) -> Owners:
  match v:
    case Lint.View{owner, inst, kind, name, q, span, inner}:
      Owners.note(acc, owner, inst, span)

# A fold_facts step: records each fact's owner.
def Owners.collect(acc: Owners, +f: Lint.Fact) -> IO(Owners):
  do IO<Owners>:
    v : Lint.View <- Lint.view(f)
    return Owners.add(acc, v)

# The owners in order of first appearance.
def Owners.ordered(o: Owners) -> List<&2, Seen>:
  match o:
    case Owners{list, set}:
      List.reverse(&2, Seen, list)

# Diagnostics
# ===========
def diag(sev: Lint.Severity, message: String, span: Maybe<&2, Lint.Span>) -> Lint.Diag:
  Lint.Diag{sev, message, span, []}

# One diagnostic when `hit`, else none.
def when(hit: Bool, d: Lint.Diag) -> List<&2, Lint.Diag>:
  match hit:
    case True{}:
      [d]
    case False{}:
      []

def onto(xs: List<&2, Lint.Diag>, out: List<&2, Lint.Diag>) -> List<&2, Lint.Diag>:
  match xs:
    case Nil{}:
      out
    case Con{x, rest}:
      onto(rest, x <> out)

# Names
# =====
# The part of a global name after its file's namespace: `b:helper` is `helper`.
def local(+name: String) -> String:
  Maybe.default(&2, String, List.last(&2, String, String.split(name, ':')), name)

# Whether a global name comes from a BendHub package (`0x<hash>/file:name`): not this project's code.
def is_package(name: String) -> Bool:
  String.starts_with(name, "0x")

# Whether a name is in a set.
def has(s: Set(), name: String) -> Bool:
  Pair.snd(Set(), Bool, Set.has(s, name))

# Graph of references between globals
# ====================================
# Lists of names under a name, last added first.
def Edges.add.of(
  got: Map<&2, List<&2, String>> & List<&2, String>,
  key: String,
  x: String
) -> Map<&2, List<&2, String>>:
  match got:
    case Tuple{m, old}:
      Map.set(&2, List<&2, String>, m, key, x <> old)

def Edges.add(
  m: Map<&2, List<&2, String>>,
  +key: String,
  x: String
) -> Map<&2, List<&2, String>>:
  Edges.add.of(Map.get(List<&2, String>, [], m, key), key, x)

# The names under `key`, last added first; the map is only read.
def Edges.of(+m: Map<&2, List<&2, String>>, key: String) -> List<&2, String>:
  Pair.snd(
    Map<&2, List<&2, String>>,
    List<&2, String>,
    Map.get(List<&2, String>, [], m, key)
  )

# What the facts say: the owners, `edges` (owner -> names it references, with repeats), and `into`
# (name -> owners that reference it, with repeats). A name an owner uses for itself is no edge.
type Graph is Data:
  Graph{owners: Owners, edges: Map<&2, List<&2, String>>, into: Map<&2, List<&2, String>>}

def Graph.empty() -> Graph:
  Graph{Owners.empty(), Map.new(&2, List<&2, String>), Map.new(&2, List<&2, String>)}

def Graph.link(
  hit: Bool,
  +owner: String,
  +name: String,
  owners: Owners,
  edges: Map<&2, List<&2, String>>,
  into: Map<&2, List<&2, String>>
) -> Graph:
  match hit:
    case True{}:
      Graph{owners, Edges.add(edges, owner, name), Edges.add(into, name, owner)}
    case False{}:
      Graph{owners, edges, into}

def Graph.add.of(
  g: Graph,
  +owner: String,
  +inst: Bool,
  +kind: String,
  +name: String,
  span: Maybe<&2, Lint.Span>
) -> Graph:
  match g:
    case Graph{owners, edges, into}:
      Graph.link(
        Bool.and(
          Bool.not(inst),
          Bool.and(
            String.eq(kind, "Ref"),
            Bool.and(Bool.not(String.is_empty(name)), Bool.not(String.eq(name, owner)))
          )
        ),
        owner,
        name,
        Owners.note(owners, owner, inst, span),
        edges,
        into
      )

def base.of(parts: List<&2, String>, name: String) -> String:
  match parts:
    case Con{h, t}:
      h
    case Nil{}:
      name

# A template call refers to an instance, `twice~0`, and a template's own parameter is `twice~f`: both
# are the template, `twice`.
def base(+name: String) -> String:
  base.of(String.split(name, '~'), name)

def Graph.add(g: Graph, v: Lint.View) -> Graph:
  match v:
    case Lint.View{owner, inst, kind, name, q, span, inner}:
      Graph.add.of(g, owner, inst, kind, base(name), span)

# A fold_facts step.
def Graph.collect(g: Graph, +f: Lint.Fact) -> IO(Graph):
  do IO<Graph>:
    v : Lint.View <- Lint.view(f)
    return Graph.add(g, v)

# Laws
# ====
# Laws are specs, not code: a def that fills one is a proof. They are found in the text (`law name:`
# at the start of a line), as the checker gives a law and its proof one owner and no flag.
def Laws.name(parts: List<&2, String>) -> List<&2, String>:
  match parts:
    case Con{h, t}:
      [h]
    case Nil{}:
      []

def Laws.line(+line: String) -> List<&2, String>:
  Bool.pick(
    List<&2, String>,
    String.starts_with(line, "law "),
    Laws.name(String.split(String.drop(line, 4n), ':')),
    []
  )

def Laws.add(names: List<&2, String>, out: Set()) -> Set():
  match names:
    case Nil{}:
      out
    case Con{n, rest}:
      Laws.add(rest, Set.add(out, n))

def Laws.lines(ls: List<&2, String>, out: Set()) -> Set():
  match ls:
    case Nil{}:
      out
    case Con{l, rest}:
      Laws.lines(rest, Laws.add(Laws.line(l), out))

# The names of the laws written in the `sources` whose paths are in `paths`.
def Laws.scan(read: Bool, text: String, out: Set()) -> Set():
  match read:
    case True{}:
      Laws.lines(String.lines(text), out)
    case False{}:
      out

# A call evaluates its arguments, so a file is split into lines only through a match: Base is long.
def Laws.sources(sources: List<&2, Lint.Source>, +paths: Set(), out: Set()) -> Set():
  match sources:
    case Nil{}:
      out
    case Con{Lint.Source{path, text, root}, rest}:
      Laws.sources(rest, paths, Laws.scan(has(paths, path), text, out))

# The paths the owners' spans are in.
def Paths.of(seen: List<&2, Seen>, out: Set()) -> Set():
  match seen:
    case Nil{}:
      out
    case Con{Seen{owner, Some{Lint.Span{path, beg, end}}}, rest}:
      Paths.of(rest, Set.add(out, path))
    case Con{x, rest}:
      Paths.of(rest, out)

# The local names of every law in the program's own files.
def Laws.of(sources: List<&2, Lint.Source>, owners: Owners) -> Set():
  Laws.sources(sources, Paths.of(Owners.ordered(owners), Set.new()), Set.new())

# Whether `owner` is a law or the proof that fills one.
def Laws.has(laws: Set(), owner: String) -> Bool:
  has(laws, local(owner))

# Owners that have a checked body
# ===============================
# Defs and laws have one; types and constructors do not.
def Bodies.put(b: Maybe<&2, Lint.Node>, owner: String, out: Set()) -> Set():
  match b:
    case Some{n}:
      Set.add(out, owner)
    case None{}:
      out

def Bodies.of(seen: List<&2, Seen>, out: Set()) -> IO(Set()):
  match seen:
    case Nil{}:
      IO.pure(Set(), out)
    case Con{Seen{+owner, span}, rest}:
      do IO<Set()>:
        b : Maybe<&2, Lint.Node> <- Lint.body(owner)
        Bodies.of(rest, Bodies.put(b, owner, out))

# Entry lists: `a, b, prefix*`
# ============================
# Whether the entry `e` names `name`: the same, or, if it ends in `*`, a prefix of it.
def Entry.hit(+e: String, +name: String) -> Bool:
  Bool.pick(
    Bool,
    String.ends_with(e, "*"),
    String.starts_with(name, String.take(e, Nat.sub(String.length(e), 1n))),
    String.eq(e, name)
  )

# Whether some entry names `owner`, as written or without its namespace.
def Entry.any(entries: List<&2, String>, +owner: String) -> Bool:
  match entries:
    case Nil{}:
      False{}
    case Con{+e, rest}:
      Bool.or(
        Bool.or(Entry.hit(e, owner), Entry.hit(e, local(owner))),
        Entry.any(rest, owner)
      )

def Entry.trim(xs: List<&2, String>) -> List<&2, String>:
  match xs:
    case Nil{}:
      []
    case Con{x, rest}:
      String.trim(x) <> Entry.trim(rest)

# A comma-separated option as a list.
def Entry.parse(text: String) -> List<&2, String>:
  Entry.trim(String.split(text, ','))

# The program's own code
# ======================
# The defs of the program: owners with a checked body that are not laws, proofs or package code.
def Nodes.put(hit: Bool, owner: String, out: Set()) -> Set():
  match hit:
    case True{}:
      Set.add(out, owner)
    case False{}:
      out

def Nodes.is(+bodies: Set(), +laws: Set(), +owner: String) -> Bool:
  Bool.and(
    has(bodies, owner),
    Bool.and(Bool.not(Laws.has(laws, owner)), Bool.not(is_package(owner)))
  )

def Nodes.of(seen: List<&2, Seen>, +bodies: Set(), +laws: Set(), out: Set()) -> Set():
  match seen:
    case Nil{}:
      out
    case Con{Seen{+owner, span}, rest}:
      Nodes.of(rest, bodies, laws, Nodes.put(Nodes.is(bodies, laws, owner), owner, out))

# Everything a graph rule reads: the owners in order, the reference maps, the set of defs, and the
# local names of the laws.
type Prog is Data:
  Prog{
    seen: List<&2, Seen>,
    edges: Map<&2, List<&2, String>>,
    into: Map<&2, List<&2, String>>,
    nodes: Set(),
    laws: Set()
  }

def Prog.with(
  +laws: Set(),
  +seen: List<&2, Seen>,
  edges: Map<&2, List<&2, String>>,
  into: Map<&2, List<&2, String>>,
  bodies: Set()
) -> Prog:
  Prog{seen, edges, into, Nodes.of(seen, bodies, laws, Set.new()), laws}

def Prog.build(
  sources: List<&2, Lint.Source>,
  +seen: List<&2, Seen>,
  edges: Map<&2, List<&2, String>>,
  into: Map<&2, List<&2, String>>,
  bodies: Set()
) -> Prog:
  Prog.with(
    Laws.sources(sources, Paths.of(seen, Set.new()), Set.new()),
    seen,
    edges,
    into,
    bodies
  )

def Prog.owners(
  sources: List<&2, Lint.Source>,
  +seen: List<&2, Seen>,
  edges: Map<&2, List<&2, String>>,
  into: Map<&2, List<&2, String>>
) -> IO(Prog):
  do IO<Prog>:
    bodies : Set() <- Bodies.of(seen, Set.new())
    return Prog.build(sources, seen, edges, into, bodies)

def Prog.of(sources: List<&2, Lint.Source>, g: Graph) -> IO(Prog):
  match g:
    case Graph{owners, edges, into}:
      Prog.owners(sources, Owners.ordered(owners), edges, into)

# Degrees
# =======
# A count of the different names that are defs, and the names counted.
type Count is Data:
  Count{seen: Set(), n: U32}

def Count.put(hit: Bool, +x: String, seen: Set(), n: U32) -> Count:
  match hit:
    case True{}:
      Count{Set.add(seen, x), U32.add(n, 1)}
    case False{}:
      Count{seen, n}

def Count.add(is_def: Bool, +x: String, c: Count) -> Count:
  match c:
    case Count{+seen, n}:
      Count.put(Bool.and(is_def, Bool.not(has(seen, x))), x, seen, n)

def Count.n(c: Count) -> U32:
  match c:
    case Count{seen, n}:
      n

def distinct(names: List<&2, String>, +nodes: Set(), c: Count) -> Count:
  match names:
    case Nil{}:
      c
    case Con{+x, rest}:
      distinct(rest, nodes, Count.add(has(nodes, x), x, c))

def degree.go(is_def: Bool, names: List<&2, String>, nodes: Set()) -> U32:
  match is_def:
    case True{}:
      Count.n(distinct(names, nodes, Count{Set.new(), 0}))
    case False{}:
      0

# The number of different defs of the program that `owner` has under it in `m` (the defs it uses,
# for `edges`; the defs that use it, for `into`). 0 for what is not a def.
def degree(+m: Map<&2, List<&2, String>>, +nodes: Set(), +owner: String) -> U32:
  degree.go(has(nodes, owner), Edges.of(m, owner), nodes)

# Where to report
# ===============
# By default a rule reports only in the linted file, though it reads the whole program: the
# imported files are libraries to it. The `imports` option widens that to every file of the program.
type Scope is Data:
  Scope{imports: Bool, root: String}

def root_path(sources: List<&2, Lint.Source>) -> String:
  match sources:
    case Nil{}:
      ""
    case Con{Lint.Source{+path, text, root}, rest}:
      Bool.pick(String, root, path, root_path(rest))

def Scope.of(sources: List<&2, Lint.Source>, options: List<&2, Lint.Option>) -> Scope:
  Scope{Lint.option_flag(options, "imports", False{}), root_path(sources)}

def in_root(+root: String, span: Maybe<&2, Lint.Span>) -> Bool:
  match span:
    case Some{Lint.Span{path, beg, end}}:
      String.eq(path, root)
    case None{}:
      False{}

def Scope.has(scope: Scope, span: Maybe<&2, Lint.Span>) -> Bool:
  match scope:
    case Scope{imports, root}:
      Bool.or(imports, in_root(root, span))

def scoped.put(hit: Bool, owner: String, span: Maybe<&2, Lint.Span>, out: List<&2, Seen>) -> List<&2, Seen>:
  match hit:
    case True{}:
      Seen{owner, span} <> out
    case False{}:
      out

# The owners a rule reports on.
def scoped(+scope: Scope, seen: List<&2, Seen>) -> List<&2, Seen>:
  match seen:
    case Nil{}:
      []
    case Con{Seen{owner, +span}, rest}:
      scoped.put(Scope.has(scope, span), owner, span, scoped(scope, rest))
