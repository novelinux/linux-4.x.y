fork_exec_helloworld
========================================

path: helloworld.c
```
#include <stdio.h>

int main(int argc, char* argv[])
{
    printf("hello world\n");
    return 0;
}
```

path: fork_exec_helloworld.c
```
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
```

编译运行:

```
$ gcc helloworld.c -o helloworld
$ ./helloworld
hello world
$ gcc fork_exec_helloworld.c -o fork
$ ./fork
execute parent process: 22355
execute child process: 22356
hello world
```
