import Base

type Color is Data:
  Red{}
  Green{}
  Blue{}

def branchy(c: Color) -> U32:
  match c:
    case Red{}:
      1
    case Green{}:
      2
    case Blue{}:
      3
