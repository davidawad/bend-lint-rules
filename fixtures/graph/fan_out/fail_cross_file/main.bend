import Base
import ./util.bend as U

def local() -> U32:
  1

# two defs of util.bend and one of this file
def hub() -> U32:
  (U.a() + U.b() + local() : U32)
