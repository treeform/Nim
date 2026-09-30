/* Exercise persistent library state across musl dlclose calls. */
static int calls;

int counter(void) {
  return ++calls;
}
