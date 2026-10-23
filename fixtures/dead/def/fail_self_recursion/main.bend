import Base

def count(n: Nat) -> Nat:
  match n:
    case 0n:
      0n
    case 1n+p:
      count(p)

def main() -> U32:
  1
