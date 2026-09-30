discard """
  disabled: "windows"
  disabled: "osx"
  disabled: "arm64"
  disabled: "arm"
  joinable: false
"""

import std/[assertions, compilesettings, os, osproc, strutils, tempfiles]

const Source = """
import std/[assertions, hotcodereloading, os, osproc]
import value

const Command = RebuildCommand

doAssert current() == 1
for expected in 2 .. 3:
  writeFile(currentSourcePath().parentDir / "value.nim",
    "proc current*(): int =\n" &
    "  ## Returns the current library generation.\n  " &
    $expected & "\n")
  let (output, status) = execCmdEx(Command)
  doAssert status == 0, output
  doAssert hasAnyModuleChanged()
  performCodeReload()
  doAssert current() == expected
"""

proc run(command: string) =
  ## Runs a command and reports its output on failure.
  let (output, status) = execCmdEx(command)
  doAssert status == 0, output

block:
  let
    directory = createTempDir("nim-hcr-", "")
    compiler = getCurrentCompilerExe().quoteShell
    library = querySetting(libPath)
    hadPath = existsEnv("LD_LIBRARY_PATH")
    path = getEnv("LD_LIBRARY_PATH")
    executable = directory / "main"
  defer:
    removeDir(directory)
    if hadPath:
      putEnv("LD_LIBRARY_PATH", path)
    else:
      delEnv("LD_LIBRARY_PATH")
  putEnv("LD_LIBRARY_PATH", directory & ":" & path)
  for name in ["nimrtl", "nimhcr"]:
    run(compiler & " c --hints:off --mm:refc --threads:off --out:" &
      (directory / ("lib" & name & ".so")).quoteShell & " " &
      (library / (name & ".nim")).quoteShell)
  writeFile(directory / "value.nim",
    "proc current*(): int =\n" &
    "  ## Returns the current library generation.\n  1\n")
  let build = compiler &
    " c --hints:off --mm:refc --threads:off --hotCodeReloading:on" &
    " --nimcache:" & (directory / "cache").quoteShell &
    " --out:" & executable.quoteShell & " " &
    (directory / "main.nim").quoteShell
  writeFile(directory / "main.nim",
    Source.replace("RebuildCommand", build.escape))
  run(build)
  run(executable.quoteShell)
