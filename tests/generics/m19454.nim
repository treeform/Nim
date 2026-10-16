import std/[tables, xmlparser, xmltree]

proc countNodes*(root: string | XmlNode): int =
  ## Counts nodes using the iterator imported at the definition site.
  when root is string:
    let root = parseXml(root)
  for node in root:
    inc result

proc countPairs*[T](value: T): int =
  ## Exercises implicit pairs without importing tables at the call site.
  var entries = initTable[int, T]()
  entries[1] = value
  entries[2] = value
  for key, item in entries:
    result += key

proc countExplicit*[T](values: seq[T]): int =
  ## Keeps explicit iterator calls distinct from implicit iteration.
  for value in values.items:
    inc result

proc countClosure*[T](value: T): int =
  ## Preserves loops over closure iterator calls.
  iterator values(): T {.closure.} =
    yield value
    yield value
  for item in values():
    inc result
