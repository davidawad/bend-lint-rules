import Base

def target() -> U32:
  1

# one caller, however often it calls: fan-in counts different defs
def caller() -> U32:
  (target() + target() + target() + target() + target() : U32)

# a def that calls itself is not its own caller
def count(n: Nat) -> Nat:
  match n:
    case 0n:
      0n
    case 1n+p:
      count(p)
