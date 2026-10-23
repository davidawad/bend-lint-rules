import Base

def target() -> U32:
  1

def caller1() -> U32:
  target()

def caller2() -> U32:
  target()

def caller3() -> U32:
  target()
