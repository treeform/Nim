discard """
  disabled: "windows"
  targets: "c cpp"
  matrix: "--mm:orc; --mm:refc"
"""

import std/[assertions, locks, oserrors, osproc, posix, strutils]

proc posixError(code: cint, buffer: cstring, size: csize_t): cint {.
  importc: "strerror_r", header: "<string.h>".}
  ## Uses the POSIX strerror_r signature supplied by musl.

block:
  var buffer = newString(256)
  doAssert posixError(ENOENT, cstring(buffer), 256) == 0
  doAssert $cstring(buffer) == osErrorMsg(OSErrorCode(ENOENT))

block:
  var lock: Lock
  initLock(lock)
  doAssert tryAcquire(lock)
  release(lock)
  deinitLock(lock)

block:
  var descriptors: array[2, cint]
  doAssert pipe(descriptors) == 0
  defer:
    discard close(descriptors[0])
    discard close(descriptors[1])
  doAssert fcntl(descriptors[0], F_SETFD, FD_CLOEXEC) == 0
  doAssert (fcntl(descriptors[0], F_GETFD) and FD_CLOEXEC) != 0

block:
  let result = execCmdEx("printf alpine")
  doAssert result.exitCode == 0 and result.output == "alpine\n"
  doAssert find("a needle in text", "needle") == 2
  doAssert getpwnam("root") != nil
  doAssert getgrnam("root") != nil
  doAssert sysconf(SC_PAGESIZE) > 0
  doAssert pathconf("/tmp", PC_NAME_MAX) > 0
