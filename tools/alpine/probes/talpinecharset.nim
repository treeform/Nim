discard """
  disabled: "windows"
  targets: "c cpp"
  matrix: "--mm:orc; --mm:refc"
"""

import std/[assertions, encodings]

doAssert convert("caf\xe9", "UTF-8", "CP1252") == "café"
doAssert convert("\xff\xfeA\x00", "UTF-8", "UTF-16") == "A"
doAssert convert("\xfe\xff\x00A", "UTF-8", "UTF-16") == "A"
doAssert convert("\xff\xfe\x00\x00A\x00\x00\x00",
  "UTF-8", "UTF-32") == "A"
doAssert convert("\x00\x00\xfe\xff\x00\x00\x00A",
  "UTF-8", "UTF-32") == "A"
doAssert convert("€", "ASCII", "UTF-8") == "*"
doAssertRaises(EncodingError):
  discard encodings.open("ASCII//TRANSLIT", "UTF-8")
doAssertRaises(EncodingError):
  discard encodings.open("GBK", "UTF-8")
doAssert convert("\xcd\xf2", "UTF-8", "GBK") == "万"
