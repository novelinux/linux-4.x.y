/**
 * Copyright (c) 2014 The DocLinux Open Document Project
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 as
 * published by the Free Software Foundation.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>

#include <fcntl.h>
#include <unistd.h>

int main(int argc, char* argv[])
{
    int pid = fork();

    if (pid < 0) {
        fprintf(stderr, "fork a subprocess error: %d, %s",
                errno, strerror(errno));
        return EXIT_FAILURE;
    } else if (pid == 0) { /* child process */
        printf("execute child process: %d\n", getpid());
        execl("./helloworld", "helloworld", NULL);
        fprintf(stderr, "exec a subprocess error: %d, %s",
                errno, strerror(errno));
    }

    printf("execute parent process: %d\n", getpid());
    /* parent process */
    if (waitpid(pid, NULL, 0) < 0) {
        fprintf(stderr, "wait a subprocess error: %d, %s",
                errno, strerror(errno));
    }

    return EXIT_SUCCESS;
}
