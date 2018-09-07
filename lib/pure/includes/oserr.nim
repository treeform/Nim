## Include file that implements 'osErrorMsg' and friends. Do not import it!

when not declared(ospaths):
  {.error: "This is an include file for ospaths.nim!".}

when not defined(nimscript):
  var errno {.importc, header: "<errno.h>".}: cint

  proc c_strerror(errnum: cint): cstring {.
    importc: "strerror", header: "<string.h>".}

  when defined(windows):
    import winlean

proc `==`*(err1, err2: OSErrorCode): bool {.borrow.}
proc `$`*(err: OSErrorCode): string {.borrow.}

proc osErrorMsg*(errorCode: OSErrorCode): string =
  ## Converts an OS error code into a human readable string.
  ##
  ## The error code can be retrieved using the ``osLastError`` proc.
  ##
  ## If conversion fails, or ``errorCode`` is ``0`` then ``""`` will be
  ## returned.
  ##
  ## On Windows, the ``-d:useWinAnsi`` compilation flag can be used to
  ## make this procedure use the non-unicode Win API calls to retrieve the
  ## message.
  result = ""
  when defined(nimscript):
    discard
  elif defined(Windows):
    if errorCode != OSErrorCode(0'i32):
      when useWinUnicode:
        var msgbuf: WideCString
        if formatMessageW(0x00000100 or 0x00001000 or 0x00000200,
                        nil, errorCode.int32, 0, addr(msgbuf), 0, nil) != 0'i32:
          result = $msgbuf
          if msgbuf != nil: localFree(cast[pointer](msgbuf))
      else:
        var msgbuf: cstring
        if formatMessageA(0x00000100 or 0x00001000 or 0x00000200,
                        nil, errorCode.int32, 0, addr(msgbuf), 0, nil) != 0'i32:
          result = $msgbuf
          if msgbuf != nil: localFree(msgbuf)
  else:
    if errorCode != OSErrorCode(0'i32):
      result = $c_strerror(errorCode.int32)

proc raiseOSError*(errorCode: OSErrorCode; additionalInfo = "") {.noinline.} =
  ## Raises an ``OSError`` exception. The ``errorCode`` will determine the
  ## message, ``osErrorMsg`` will be used to get this message.
  ##
  ## The error code can be retrieved using the ``osLastError`` proc.
  ##
  ## If the error code is ``0`` or an error message could not be retrieved,
  ## the message ``unknown OS error`` will be used.
  var e: ref OSError; new(e)
  e.errorCode = errorCode.int32
  if additionalInfo.len == 0:
    e.msg = osErrorMsg(errorCode)
  else:
    e.msg = osErrorMsg(errorCode) & "\nAdditional info: '" & additionalInfo & "'"
  if e.msg == "":
    e.msg = "unknown OS error"
  raise e

{.push stackTrace:off.}
proc osLastError*(): OSErrorCode {.sideEffect.} =
  ## Retrieves the last operating system error code.
  ##
  ## This procedure is useful in the event when an OS call fails. In that case
  ## this procedure will return the error code describing the reason why the
  ## OS call failed. The ``OSErrorMsg`` procedure can then be used to convert
  ## this code into a string.
  ##
  ## **Warning**:
  ## The behaviour of this procedure varies between Windows and POSIX systems.
  ## On Windows some OS calls can reset the error code to ``0`` causing this
  ## procedure to return ``0``. It is therefore advised to call this procedure
  ## immediately after an OS call fails. On POSIX systems this is not a problem.
  when defined(nimscript):
    discard
  elif defined(windows):
    result = OSErrorCode(getLastError())
  else:
    result = OSErrorCode(errno)
{.pop.}
