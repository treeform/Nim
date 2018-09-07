#! /bin/sh

# build development version of the compiler; can be rerun safely

set -u # error on undefined variables
set -e # exit on first error

echo_run(){
  echo "\n$@"
  "$@"
}

[ -d csources ] || echo_run git clone --depth 1 https://github.com/nim-lang/csources.git

nim_csources=bin/nim_csources
build_nim_csources(){
  ## avoid changing dir in case of failure
  (
    echo_run cd csources
    echo_run sh build.sh
  )
  # keep $nim_csources in case needed to investigate bootstrap issues
  # without having to rebuild from csources
  echo_run cp bin/nim $nim_csources
}

[ -f $nim_csources ] || echo_run build_nim_csources

echo_run bin/nim c koch
echo_run ./koch boot -d:release
echo_run ./koch tools # Compile Nimble and other tools.
