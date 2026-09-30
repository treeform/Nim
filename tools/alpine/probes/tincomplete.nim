discard """
  targets: "c cpp"
  matrix: "--mm:arc; --mm:orc"
"""

import std/[assertions, syncio]

when defined(posix):
  import std/posix

type Wrapper = object
  file: File

when defined(gcArc) or defined(gcOrc):
  doAssert repr(stdout) == $typeof(stdout) & "()"
  doAssert repr(Wrapper(file: stdout)) ==
    "Wrapper(file: " & $typeof(stdout) & "())"
else:
  doAssert repr(stdout).len > 0
  doAssert repr(Wrapper(file: stdout)).len > 0
doAssert repr(File(nil)) == "nil"

when defined(posix):
  block:
    let directory = opendir(".")
    doAssert directory != nil
    defer: discard closedir(directory)
    when defined(gcArc) or defined(gcOrc):
      doAssert repr(directory) == $typeof(directory) & "()"
    else:
      doAssert repr(directory).len > 0
