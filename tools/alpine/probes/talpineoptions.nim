discard """
  targets: "c cpp"
  matrix: "--mm:orc; --mm:refc"
"""

import std/[assertions, complex, math, parseopt, strutils]

block:
  var arguments: seq[string]
  var options: seq[string]
  var parser = initOptParser(@["file", "-v", "--name=value"])
  for kind, key, value in parser.getopt():
    case kind
    of cmdArgument:
      arguments.add(key)
    of cmdShortOption:
      doAssert key == "v"
      options.add(key)
    of cmdLongOption:
      doAssert key == "name" and value == "value"
      options.add(key)
    of cmdEnd:
      doAssert false
  doAssert arguments == @["file"]
  doAssert options == @["v", "name"]

doAssert formatFloat(1.25, ffDecimal, 2) == "1.25"
doAssert abs(gamma(5.0) - 24.0) < 0.00001
block:
  let number = complex(3.0, 4.0)
  doAssert abs(number) == 5.0
  doAssert abs(sqrt(number) * sqrt(number) - number) < 0.00001
