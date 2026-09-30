#!/usr/bin/env bash
set -euo pipefail

. ci/funs.sh
case "$(uname -m)" in
  x86_64) cpu=amd64 ;;
  aarch64) cpu=arm64 ;;
  *) echo "Only amd64 and arm64 Alpine are supported" >&2; exit 1 ;;
esac
nimBuildCsourcesIfNeeded CC=gcc ucpu="$cpu"
bin/nim c --lib:lib --out:koch koch.nim
./koch boot -d:release --lib:lib
for memory in orc refc; do
  bin/nim check --mm:"$memory" tests/stdlib/talpine.nim
  bin/nim c -r --mm:"$memory" tests/stdlib/talpine.nim
done
bin/nim check tests/dll/thcrreload.nim
bin/nim c -r tests/dll/thcrreload.nim
