import std/[assertions, posix]

block:
  var
    attributes: Pthread_attr
    guardSize, stackSize: csize_t
    stack: pointer
    state: cint
  doAssert pthread_attr_init(addr attributes) == 0
  defer:
    doAssert pthread_attr_destroy(addr attributes) == 0
  doAssert pthread_attr_setguardsize(addr attributes, 8192) == 0
  doAssert pthread_attr_getguardsize(addr attributes, guardSize) == 0
  doAssert guardSize == 8192
  doAssert pthread_attr_setstacksize(addr attributes, 2 * 1024 * 1024) == 0
  doAssert pthread_attr_getstacksize(addr attributes, stackSize) == 0
  doAssert stackSize == 2 * 1024 * 1024
  let storage = allocShared(2 * 1024 * 1024)
  doAssert storage != nil
  defer:
    deallocShared(storage)
  doAssert pthread_attr_setstack(addr attributes, storage, 2 * 1024 * 1024) == 0
  doAssert pthread_attr_getstack(addr attributes, stack, stackSize) == 0
  doAssert stack == storage
  doAssert stackSize == 2 * 1024 * 1024
  doAssert pthread_attr_setdetachstate(addr attributes, PTHREAD_CREATE_JOINABLE) == 0
  doAssert pthread_attr_getdetachstate(addr attributes, state) == 0
  doAssert state == PTHREAD_CREATE_JOINABLE
