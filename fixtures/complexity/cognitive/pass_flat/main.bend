import Base

type Op is Data:
  O0{}
  O1{}
  O2{}
  O3{}
  O4{}

# many arms of one match do not nest in each other: cognitive complexity 1
def flat(o: Op) -> U32:
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

def straight(x: U32) -> U32:
  x
