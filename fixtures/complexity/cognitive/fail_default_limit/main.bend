import Base

# five nested matches: 1 + 2 + 3 + 4 + 5 = 15, the default limit
def five(a: Bool, b: Bool, c: Bool, d: Bool, e: Bool) -> U32:
  match a:
    case True{}:
      match b:
        case True{}:
          match c:
            case True{}:
              match d:
                case True{}:
                  match e:
                    case True{}:
                      1
                    case False{}:
                      2
                case False{}:
                  3
            case False{}:
              4
        case False{}:
          5
    case False{}:
      6

# six nested matches: 21
def six(a: Bool, b: Bool, c: Bool, d: Bool, e: Bool, f: Bool) -> U32:
  match a:
    case True{}:
      match b:
        case True{}:
          match c:
            case True{}:
              match d:
                case True{}:
                  match e:
                    case True{}:
                      match f:
                        case True{}:
                          1
                        case False{}:
                          2
                    case False{}:
                      3
                case False{}:
                  4
            case False{}:
              5
        case False{}:
          6
    case False{}:
      7
