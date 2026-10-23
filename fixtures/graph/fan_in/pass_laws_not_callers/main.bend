import Base

def target() -> U32:
  1

def caller() -> U32:
  target()

# laws are specs, not callers
law t1:
  {target() == 1 : U32}

law t2:
  {target() == 1 : U32}

law t3:
  {target() == 1 : U32}

def t1():
  {==}

def t2():
  {==}

def t3():
  {==}
