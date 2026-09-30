/* Check musl behavior independently of Nim. */
#define _GNU_SOURCE
#include <assert.h>
#include <errno.h>
#include <fenv.h>
#include <getopt.h>
#include <stdio.h>
#include <string.h>
#include <utmp.h>

int main(void) {
  char buffer[64];
  char *arguments[] = {"tool", "file", "-v", NULL};
  assert(getopt(3, arguments, "v") == -1);
  assert(optind == 1);
  assert(fesetround(FE_DOWNWARD) == 0);
  snprintf(buffer, sizeof buffer, "%.1f", 1.25);
  assert(strcmp(buffer, "1.2") == 0);
  assert(fesetround(FE_UPWARD) == 0);
  snprintf(buffer, sizeof buffer, "%.1f", 1.25);
  assert(strcmp(buffer, "1.3") == 0);
  setutent();
  assert(getutent() == NULL);
  endutent();
  return 0;
}
