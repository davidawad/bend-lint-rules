import Base

type Color is Data:
  Red{}
  Green{}
  Blue{}

def three(c: Color) -> U32:
  match c:
    case Red{}:
      1
    case Green{}:
      2
    case Blue{}:
      3

def two(c: Color) -> U32:
  match c:
    case Red{}:
      1
    case _:
      2

def straight(x: U32) -> U32:
  x
