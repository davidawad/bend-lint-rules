import Base

type Op is Data:
  O0{}
  O1{}
  O2{}
  O3{}
  O4{}
  O5{}
  O6{}
  O7{}
  O8{}
  O9{}
  O10{}
  O11{}

# nine arms and a `_`: complexity 10, the default limit
def ten(o: Op) -> U32:
  match o:
    case O0{}:
      0
    case O1{}:
      1
    case O2{}:
      2
    case O3{}:
      3
    case O4{}:
      4
    case O5{}:
      5
    case O6{}:
      6
    case O7{}:
      7
    case O8{}:
      8
    case _:
      9

# ten arms and a `_`: complexity 11
def eleven(o: Op) -> U32:
  match o:
    case O0{}:
      0
    case O1{}:
      1
    case O2{}:
      2
    case O3{}:
      3
    case O4{}:
      4
    case O5{}:
      5
    case O6{}:
      6
    case O7{}:
      7
    case O8{}:
      8
    case O9{}:
      9
    case _:
      10
