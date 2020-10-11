/**
 * @file LibA.h
 * 
 * @brief Project A - Library A
 */

#include <stdio.h>

/**
 * @brief Print arguments prefixed with "ProjectA"
 * 
 * Print one line of text to STDOUT for each argument given.
 * Format is "ProjectA: argv[%d] : %s".
 * 
 * @param argc Number of command-line arguments
 * @param argv Command-line arguments as a string array
 */
void project_a_print_args(int argc, char *argv[]);
