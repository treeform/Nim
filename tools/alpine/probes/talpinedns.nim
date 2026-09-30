discard """
  disabled: "windows"
"""

import std/[assertions, nativesockets, posix]

for hostname in ["node", "node.audit.test.", "tcp.audit.test"]:
  let info = getAddrInfo(hostname, Port(80), AF_INET, SOCK_STREAM)
  defer: freeAddrInfo(info)
  var address: array[64, char]
  doAssert getnameinfo(info.ai_addr, info.ai_addrlen,
    cast[cstring](addr address[0]), SockLen(address.len), nil, 0,
    NI_NUMERICHOST) == 0
  doAssert $cast[cstring](addr address[0]) == "127.0.0.42"
