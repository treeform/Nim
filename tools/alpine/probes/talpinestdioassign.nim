discard """
  disabled: "windows"
  targets: "c cpp"
  matrix: "--mm:orc; --mm:refc"
"""

import std/[assertions, os, syncio, tempfiles]

block:
  let
    original = stdout
    (stream, filename) = createTempFile("alpine-stdout-", ".txt")
  defer:
    stdout = original
    stream.close()
    removeFile(filename)
  stdout = stream
  stdout.write("redirected")
  stdout.flushFile()
  doAssert readFile(filename) == "redirected"
