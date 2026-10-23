import Base

def f0() -> U32:
  0

def f1() -> U32:
  1

def f2() -> U32:
  2

def f3() -> U32:
  3

def f4() -> U32:
  4

def f5() -> U32:
  5

def f6() -> U32:
  6

def f7() -> U32:
  7

def f8() -> U32:
  8

def f9() -> U32:
  9

# uses 10 different defs: the default limit
def hub() -> U32:
  (f0() + f1() + f2() + f3() + f4() + f5() + f6() + f7() + f8() + f9() : U32)
