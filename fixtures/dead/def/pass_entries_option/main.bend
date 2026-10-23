import Base

# api_one and api.add are meant for callers outside this program
def api_one() -> U32:
  1

def api.add(a: U32, b: U32) -> U32:
  (a + b : U32)

def api.helper(a: U32) -> U32:
  a

def main() -> U32:
  0
