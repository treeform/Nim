discard """
  targets: "c cpp"
  matrix: "--mm:orc; --mm:refc"
"""

import std/assertions
import m19454

doAssert countNodes("<root><first /><second /></root>") == 2
doAssert countPairs("value") == 3
doAssert countExplicit(@[1, 2, 3]) == 3
doAssert countClosure(42) == 2
