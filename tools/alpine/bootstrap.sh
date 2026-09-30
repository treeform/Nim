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
