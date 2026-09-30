discard """
  disabled: "windows"
  targets: "c cpp"
  matrix: "--mm:orc; --mm:refc"
"""

import std/[assertions, os, posix, syncio, tempfiles]

block:
  let
    (stream, filename) = createTempFile("alpine-stdout-", ".txt")
    saved = dup(getFileHandle(stdout))
  doAssert saved >= 0
  defer:
    stdout.flushFile()
    doAssert dup2(saved, getFileHandle(stdout)) >= 0
    discard close(saved)
    stream.close()
    removeFile(filename)
  stdout.flushFile()
  doAssert dup2(getFileHandle(stream), getFileHandle(stdout)) >= 0
  stdout.write("redirected")
  stdout.flushFile()
  doAssert readFile(filename) == "redirected"
