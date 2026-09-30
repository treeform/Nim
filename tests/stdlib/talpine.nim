discard """
  disabled: "windows"
  matrix: "--mm:refc; --mm:orc"
"""

import std/[assertions, math, os, posix, strutils, syncio, times]

when compileOption("threads"):
  import std/typedthreads

doAssert formatFloat(1.25, ffDecimal, 2) == "1.25"
doAssert abs(gamma(5.0) - 24.0) < 0.00001
doAssert fromUnix(0).utc.format("yyyy-MM-dd") == "1970-01-01"

block:
  var signals: Sigset
  doAssert sigemptyset(signals) == 0
  doAssert sigaddset(signals, SIGUSR1) == 0
  doAssert sigismember(signals, SIGUSR1) == 1

block:
  let filename = getTempDir() / ("nim-alpine-" & $getCurrentProcessId())
  defer: removeFile(filename)
  writeFile(filename, "musl\n")
  doAssert readFile(filename) == "musl\n"
  doAssert getFileSize(filename) == 5

when compileOption("threads"):
  proc worker() {.thread.} =
    ## Checks libc use from a Nim thread.
    doAssert formatFloat(2.5, ffDecimal, 1) == "2.5"

  var thread: Thread[void]
  createThread(thread, worker)
  joinThread(thread)
