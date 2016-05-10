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

void set_uid_map(pid_t pid, int inside_id, int outside_id, int length)
{
    char path[256];
    sprintf(path, "/proc/%d/uid_map", getpid());
    FILE* uid_map = fopen(path, "w");
    fprintf(uid_map, "%d %d %d", inside_id, outside_id, length);
    fclose(uid_map);
}

void set_gid_map(pid_t pid, int inside_id, int outside_id, int length)
{
    char path[256];
    sprintf(path, "/proc/%d/gid_map", getpid());
    FILE* gid_map = fopen(path, "w");
    fprintf(gid_map, "%d %d %d", inside_id, outside_id, length);
    fclose(gid_map);
}

static int child_main(void* args)
{
    printf("in child\n");
    set_uid_map(getpid(), 0, 1000, 1);
    set_gid_map(getpid(), 0, 1000, 1);
    printf("eUID=%u, eGID=%u\n", getuid(), getgid());
    execv(child_args[0], child_args);
    printf("child failed\n");
    return 1;
}

int main(int argc, char *argv[])
{
    printf("starting ...\n");
    /*int child_pid = clone(child_main, child_stack + STACK_SIZE,
                          CLONE_NEWUSER | SIGCHLD,
                          NULL);*/
    int child_pid = fork();
    if (child_pid == 0) {
        unshare(CLONE_NEWUSER);
        printf("in child\n");
        set_uid_map(getpid(), 0, 1000, 1);
        set_gid_map(getpid(), 0, 1000, 1);
        printf("eUID=%u, eGID=%u\n", getuid(), getgid());
        execv(child_args[0], child_args);
        printf("child failed\n");
    }

    waitpid(child_pid, NULL, 0);
    printf("exited\n");
    return 0;
}
