import Base

# reached only through the laws: live
def double(+x: Nat) -> Nat:
  Nat.add(x, x)

def zero_only(x: Nat) -> Nat:
  x
