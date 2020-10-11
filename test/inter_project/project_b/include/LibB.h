/**
 * @file LibB.h
 * 
 * @brief Project B - Library B
 */

#include <stdio.h>

/**
 * @brief Print arguments prefixed with "ProjectB"
 * 
 * Print one line of text to STDOUT for each argument given.
 * Format is "ProjectB: argv[%d] : %s".
 * 
 * @param argc Number of command-line arguments
 * @param argv Command-line arguments as a string array
 */
void project_b_print_args(int argc, char *argv[]);
