import Base

type Color is Data:
  Red{}
  Green{}
  Blue{}

# three matches, each inside an arm of the one above: 1 + 2 + 3 = 6
def deep(a: Color, b: Color, c: Color) -> U32:
  match a:
    case Red{}:
      match b:
        case Red{}:
          match c:
            case Red{}:
              1
            case _:
              2
        case _:
          3
    case _:
      4

# one match in one arm: 1 + 2 = 3
def shallow(a: Color, b: Color) -> U32:
  match a:
    case Red{}:
      match b:
        case Red{}:
          1
        case _:
          2
    case _:
      3
