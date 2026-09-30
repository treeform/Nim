discard """
  targets: "c cpp"
  matrix: "--mm:arc; --mm:orc"
"""

import std/[assertions, syncio]

when defined(posix):
  import std/posix

type Wrapper = object
  file: File

doAssert repr(stdout) == $typeof(stdout) & "()"
doAssert repr(Wrapper(file: stdout)) ==
  "Wrapper(file: " & $typeof(stdout) & "())"
doAssert repr(File(nil)) == "nil"

when defined(posix):
  block:
    let directory = opendir(".")
    doAssert directory != nil
    defer: discard closedir(directory)
    doAssert repr(directory) == $typeof(directory) & "()"
