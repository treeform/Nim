discard """
  disabled: "windows"
  targets: "c cpp"
  matrix: "--mm:refc; --mm:orc"
"""

import std/[assertions, envvars, posix, times]

const Summers = [-2193350400'i64, 962409600'i64, 2224713600'i64]

block:
  let
    hadTimezone = existsEnv("TZ")
    timezone = getEnv("TZ")
  defer:
    if hadTimezone:
      putEnv("TZ", timezone)
    else:
      delEnv("TZ")
    tzset()
  putEnv("TZ", "EST5EDT,M3.2.0/2,M11.1.0/2")
  tzset()
  for seconds in Summers:
    var stamp = cast[posix.Time](seconds)
    if stamp.int64 != seconds:
      continue
    let
      native = posix.localtime(stamp)[]
      instant = fromUnix(seconds)
      date = instant.local
    doAssert date.year == native.tm_year + 1900
    doAssert date.month.ord == native.tm_mon + 1
    doAssert date.monthday == native.tm_mday
    doAssert date.hour == native.tm_hour
    doAssert date.minute == native.tm_min
    doAssert date.isDst == (native.tm_isdst > 0)
    doAssert date.toTime == instant
