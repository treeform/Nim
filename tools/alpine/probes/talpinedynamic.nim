import std/[assertions, dynlib, os]

type Counter = proc(): cint {.cdecl.}

block:
  let filename = paramStr(1)
  var library = loadLib(filename)
  doAssert library != nil
  var counter = cast[Counter](symAddr(library, "counter"))
  doAssert counter != nil
  doAssert counter() == 1
  unloadLib(library)
  library = loadLib(filename)
  doAssert library != nil
  counter = cast[Counter](symAddr(library, "counter"))
  doAssert counter() == 2
  doAssert symAddr(library, "absentSymbol") == nil
  unloadLib(library)
  doAssert loadLib(filename & ".absent") == nil

block:
  let filename = paramStr(2)
  if filename != "skip":
    doAssert loadLib(filename) == nil
