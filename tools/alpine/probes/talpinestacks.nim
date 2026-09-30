discard """
  disabled: "windows"
  targets: "c cpp"
  matrix: "--mm:orc; --mm:refc"
"""

import std/[assertions, typedthreads]

proc worker() {.thread.} =
  ## Exercises a stack frame larger than musl's default pthread stack.
  var buffer {.volatile.}: array[512 * 1024, byte]
  for i in 0 ..< buffer.len:
    buffer[i] = byte(i and 255)
  doAssert buffer[0] == 0
  doAssert buffer[buffer.len - 1] == 255

var thread: Thread[void]
createThread(thread, worker)
joinThread(thread)
