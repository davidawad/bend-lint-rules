import Base
import ./code.bend as Code

law dbl_zero:
  {Code.double(0n) == 0n : Nat}

law open_claim:
  for x: Nat
  {Code.double(x) == Nat.add(x, x) : Nat}
