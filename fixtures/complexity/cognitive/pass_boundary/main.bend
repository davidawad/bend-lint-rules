import Base

type Color is Data:
  Red{}
  Green{}
  Blue{}

# 1 + 2 + 3 = 6, equal to max
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

# a match in the `_` arm nests too: 1 + 2 = 3
def in_default(a: Color, b: Color) -> U32:
  match a:
    case Red{}:
      1
    case _:
      match b:
        case Red{}:
          2
        case _:
          3
