#define _GNU_SOURCE
#include <sys/types.h>
#include <sys/wait.h>
#include <stdio.h>
#include <sched.h>
#include <signal.h>
#include <unistd.h>

#define STACK_SIZE (1024 * 1024)

static char child_stack[STACK_SIZE];
char* const child_args[] = {
    "/bin/bash",
    NULL
};

static int child_main(void* args)
{
    printf("in child\n");
    sethostname("changed namespace", 12);
    execv(child_args[0], child_args);
    printf("child failed\n");
    return 1;
}

int main(int argc, char *argv[])
{
    printf("starting ...\n");
    int child_pid = clone(child_main, child_stack + STACK_SIZE,
                          CLONE_NEWNET | SIGCHLD, NULL);
    waitpid(child_pid, NULL, 0);
    printf("exited\n");
    return 0;
}
