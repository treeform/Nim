#!/usr/bin/env bash
set -euo pipefail

. ci/funs.sh
case "$(uname -m)" in
  x86_64) cpu=amd64 ;;
  aarch64) cpu=arm64 ;;
  *) echo "Unsupported Alpine architecture" >&2; exit 1 ;;
esac
nimBuildCsourcesIfNeeded CC=gcc ucpu="$cpu"
bin/nim c --lib:lib --out:koch koch.nim
./koch boot -d:release --lib:lib
for memory in orc refc; do
  bin/nim check --mm:"$memory" tests/stdlib/talpine.nim
  bin/nim c -r --mm:"$memory" tests/stdlib/talpine.nim
done
for memory in orc refc; do
  bin/nim check --mm:"$memory" tests/stdlib/ttime_t.nim
  for backend in c cpp; do
    bin/nim "$backend" -r --mm:"$memory" tests/stdlib/ttime_t.nim
    if [[ "$cpu" == amd64 ]]; then
      bin/nim "$backend" --cpu:i386 --mm:"$memory" --compileOnly \
        --nimcache:"nimcache/alpine-time32-$memory-$backend" \
        tests/stdlib/ttime_t.nim
    fi
  done
done
