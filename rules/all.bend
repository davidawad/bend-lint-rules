# bend-lint-rules: BendHub entry. Importing this file publishes all five rules and their helpers
# as one package; bend-lint loads each rule from its own file (rules/*/*.bend), not from here.
#
# The rules' shared dependency on bend-lint's rule API is vendored unmodified in vendor/lint.bend
# (Apache-2.0, see vendor/LICENSE-APACHE-2.0); everything else in the package is GPL-3.0-or-later (LICENSE).
import Base
import ./dead/def.bend as DeadDef
import ./complexity/cyclomatic.bend as Cyclomatic
import ./complexity/cognitive.bend as Cognitive
import ./graph/fan_out.bend as FanOut
import ./graph/fan_in.bend as FanIn

def main() -> IO(Unit):
  IO.pure(Unit, Unit{})
