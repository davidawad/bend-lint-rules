import Base

def api_one() -> U32:
  1

def api.add(a: U32, b: U32) -> U32:
  (a + b : U32)

# not named by the entries option: still dead
def internal_dead() -> U32:
  3

def main() -> U32:
  0
