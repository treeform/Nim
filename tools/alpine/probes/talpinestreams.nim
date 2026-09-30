discard """
  disabled: "windows"
  targets: "c cpp"
  matrix: "--mm:orc; --mm:refc"
"""

import std/[assertions, os, syncio, tempfiles]

block:
  let (stream, filename) = createTempFile("alpine-", ".txt")
  defer:
    stream.close()
    removeFile(filename)
  stream.write("abc")
  stream.flushFile()
  stream.setFilePos(0)
  doAssert stream.readAll() == "abc"
  doAssert stream.endOfFile()
  stream.setFilePos(0)
  doAssert not stream.endOfFile()
  doAssert stream.readAll() == "abc"

block:
  let (stream, filename) = createTempFile("alpine-", ".sparse")
  defer:
    stream.close()
    removeFile(filename)
  stream.setFilePos(5'i64 * 1024 * 1024 * 1024)
  stream.write("x")
  stream.flushFile()
  doAssert stream.getFilePos() == 5'i64 * 1024 * 1024 * 1024 + 1
  doAssert getFileSize(filename) == stream.getFilePos()
  stream.setFilePos(-1, fspEnd)
  doAssert stream.readChar() == 'x'
