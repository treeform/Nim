import std/[assertions, dynlib, os]

doAssert loadLib(paramStr(1)) == nil
