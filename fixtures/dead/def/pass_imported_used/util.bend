import Base

def inner(x: U32) -> U32:
  x

def outer(x: U32) -> U32:
  inner(x)
