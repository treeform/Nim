import std/[assertions, re]

doAssert "musl 64".match(re"musl [0-9]+")
doAssert "hello Alpine".find(re"Alpine$") == 6
