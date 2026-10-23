import Base

def a() -> U32:
  1

def b() -> U32:
  2

def c() -> U32:
  3

# three different defs, one of them twice: fan-out 3
def hub() -> U32:
  (a() + b() + c() + a() : U32)
