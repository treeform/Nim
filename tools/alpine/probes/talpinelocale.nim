import std/[assertions, parseutils, posix, strutils, unicode]

proc compareLocale(a, b: cstring): cint {.
  importc: "strcoll", header: "<string.h>".}
  ## Compares strings using the libc locale.

block:
  let original = $setlocale(LC_ALL, nil)
  defer:
    discard setlocale(LC_ALL, original.cstring)
  doAssert setlocale(LC_ALL, "de_DE.UTF-8") != nil
  doAssert compareLocale("ä", "z") > 0
  doAssert toUpper("äöü") == "ÄÖÜ"
  var number: float
  doAssert parseFloat("1.25", number) == 4
  doAssert number == 1.25
  doAssert formatFloat(number, ffDecimal, 2) == "1.25"
