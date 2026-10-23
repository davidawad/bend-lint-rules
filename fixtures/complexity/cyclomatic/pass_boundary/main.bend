import Base

type Color is Data:
  Red{}
  Green{}
  Blue{}

# three arms: three paths
def three(c: Color) -> U32:
  match c:
    case Red{}:
      1
    case Green{}:
      2
    case Blue{}:
      3

# two arms and a `_`: three paths
def wild(c: Color) -> U32:
  match c:
    case Red{}:
      1
    case Green{}:
      2
    case _:
      3

# a match in an arm: Red/Red, Red/other, other
def nested(c: Color, d: Color) -> U32:
  match c:
    case Red{}:
      match d:
        case Red{}:
          1
        case _:
          2
    case _:
      3

def straight(x: U32) -> U32:
  x
