import Base

type Pair2 is Data:
  P{a: U32, b: U32}

# taking apart a one-constructor type decides nothing: complexity 1
def sum2(p: Pair2) -> U32:
  match p:
    case P{+a, +b}:
      (a + b : U32)

def swap(p: Pair2) -> Pair2:
  match p:
    case P{a, b}:
      P{b, a}
