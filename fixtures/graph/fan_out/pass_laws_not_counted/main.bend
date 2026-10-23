import Base

def a() -> U32:
  1

def b() -> U32:
  1

def c() -> U32:
  1

def d() -> U32:
  1

# a law that names four defs: a spec, not a def with fan-out 4
law all_one:
  {(a() + b() + c() + d() : U32) == 4 : U32}

def all_one():
  {==}
