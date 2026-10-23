import Base

type Color is Data:
  Red{}
  Green{}
  Blue{}

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
