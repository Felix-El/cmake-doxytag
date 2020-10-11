#include <LibA.h>
#include <LibB.h>

void project_b_print_args(int argc, char *argv[])
{
  project_a_print_args(argc, argv);

  for (int i = 0; i < argc; ++i) { printf("ProjectB: argv[%d] : %s", i, argv[i]); }
}
