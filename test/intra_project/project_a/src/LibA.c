#include <LibA.h>

void project_a_print_args(int argc, char *argv[])
{
  for (int i = 0; i < argc; ++i) { printf("ProjectA: argv[%d] : %s", i, argv[i]); }
}
