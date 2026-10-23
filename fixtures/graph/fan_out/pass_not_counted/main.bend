import Base

type Shape is Data:
  Circle{r: U32}
  Square{s: U32}

def a() -> U32:
  1

# Uses Base (U32.add, List), a type (Shape), itself and `a` five times: fan-out 1.
# Only different defs of the program count.
def hub(xs: List<U32>, s: Shape) -> U32:
  match xs:
    case Nil{}:
      (a() + a() + a() + a() + a() : U32)
    case Con{h, t}:
      U32.add(hub(t, s), h)
