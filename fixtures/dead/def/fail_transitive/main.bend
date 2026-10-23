import Base

def leaf(x: U32) -> U32:
  x

def middle(x: U32) -> U32:
  leaf(x)

def top_dead(x: U32) -> U32:
  middle(x)

def main() -> U32:
  1
