import Base

def a() -> U32:
  1

def b() -> U32:
  2

def c() -> U32:
  3

def d() -> U32:
  4

def hub() -> U32:
  (a() + b() + c() + d() : U32)
