/* Build with glibc to exercise an incompatible shared dependency. */
#include <gnu/libc-version.h>

const char *libc_version(void) {
  return gnu_get_libc_version();
}
