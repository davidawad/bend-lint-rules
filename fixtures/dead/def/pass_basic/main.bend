import Base

type Shape is Data:
  Circle{r: U32}
  Square{s: U32}

def area(x: Shape) -> U32:
  match x:
    case Circle{+r}:
      (3 * r * r : U32)
    case Square{+s}:
      (s * s : U32)

# a template, used from main: its instances must not count as separate defs
def twice(~f: U32 -> U32, x: U32) -> U32:
  f(f(x))

def inc(x: U32) -> U32:
  (x + 1 : U32)

# used only by the law below: a law is a spec, so what it mentions is live
def only_in_law() -> U32:
  2

law only_in_law_is_two:
  {only_in_law() == 2 : U32}

def only_in_law_is_two():
  {==}

# recursion reached from main
def sum(xs: List<U32>, acc: U32) -> U32:
  match xs:
    case Nil{}:
      acc
    case Con{h, t}:
      sum(t, (acc + h : U32))

def main() -> U32:
  U32.add(twice(~inc, area(Square{5})), sum([1, 2, 3], 0))
