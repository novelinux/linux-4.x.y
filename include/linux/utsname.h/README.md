UTS
========================================

UTS namespace提供了主机名和域名的隔离，这样每个容器就可以拥有了独立的主机名和域名，
在网络上可以被视作一个独立的节点而非宿主机上的一个进程。

Data Structure
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/utsname.h/struct uts_namespace.md

init_uts_ns
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/init/version.c/init_uts_ns.md

sample
----------------------------------------

path: uts.c
```
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
                          CLONE_NEWUTS | SIGCHLD, NULL);
    waitpid(child_pid, NULL, 0);
    printf("exited\n");
    return 0;
}
```

Results:

```
$ sudo ./uts
[sudo] password for liminghao:
starting ...
in child
# exit
exit
exited
$
```

不加CLONE_NEWUTS参数运行上述代码，发现主机名也变了，输入exit以后主机名也会变回来，
似乎没什么区别。实际上不加CLONE_NEWUTS参数进行隔离而使用sethostname已经把宿主机的
主机名改掉了。你看到exit退出后还原只是因为bash只在刚登录的时候读取一次UTS，当你
重新登陆或者使用uname命令进行查看时，就会发现产生了变化。

### CLONE_NEWUTS:

```
# ps
  PID TTY          TIME CMD
 6871 pts/22   00:00:00 sudo
 6872 pts/22   00:00:00 uts
 6873 pts/22   00:00:00 bash
 6888 pts/22   00:00:00 ps
# ls -l /proc/6873/ns/
total 0
lrwxrwxrwx 1 root root 0 Feb 18 21:06 ipc -> ipc:[4026531839]
lrwxrwxrwx 1 root root 0 Feb 18 21:06 mnt -> mnt:[4026531840]
lrwxrwxrwx 1 root root 0 Feb 18 21:06 net -> net:[4026531962]
lrwxrwxrwx 1 root root 0 Feb 18 21:06 pid -> pid:[4026531836]
lrwxrwxrwx 1 root root 0 Feb 18 21:06 user -> user:[4026531837]
lrwxrwxrwx 1 root root 0 Feb 18 21:06 uts -> uts:[4026531838]
# ls -l /proc/6873/ns/
total 0
lrwxrwxrwx 1 root root 0 Feb 18 21:07 ipc -> ipc:[4026531839]
lrwxrwxrwx 1 root root 0 Feb 18 21:07 mnt -> mnt:[4026531840]
lrwxrwxrwx 1 root root 0 Feb 18 21:07 net -> net:[4026531962]
lrwxrwxrwx 1 root root 0 Feb 18 21:07 pid -> pid:[4026531836]
lrwxrwxrwx 1 root root 0 Feb 18 21:07 user -> user:[4026531837]
lrwxrwxrwx 1 root root 0 Feb 18 21:07 uts -> uts:[4026532388]
```

可以看出uts namespace 编号并不一致,表示子进程同父进程分别占用不同的namespace.

### 不加CLONE_NEWUTS:

```
$ ps
  PID TTY          TIME CMD
 6835 pts/22   00:00:00 bash
 6929 pts/22   00:00:00 uts
 6930 pts/22   00:00:00 bash
 6942 pts/22   00:00:00 ps
$ ls -l /proc/6930/ns
total 0
lrwxrwxrwx 1 liminghao liminghao 0 Feb 18 21:13 ipc -> ipc:[4026531839]
lrwxrwxrwx 1 liminghao liminghao 0 Feb 18 21:13 mnt -> mnt:[4026531840]
lrwxrwxrwx 1 liminghao liminghao 0 Feb 18 21:13 net -> net:[4026531962]
lrwxrwxrwx 1 liminghao liminghao 0 Feb 18 21:13 pid -> pid:[4026531836]
lrwxrwxrwx 1 liminghao liminghao 0 Feb 18 21:13 user -> user:[4026531837]
lrwxrwxrwx 1 liminghao liminghao 0 Feb 18 21:13 uts -> uts:[4026531838]
$ ls -l /proc/6930/ns
total 0
lrwxrwxrwx 1 liminghao liminghao 0 Feb 18 21:13 ipc -> ipc:[4026531839]
lrwxrwxrwx 1 liminghao liminghao 0 Feb 18 21:13 mnt -> mnt:[4026531840]
lrwxrwxrwx 1 liminghao liminghao 0 Feb 18 21:13 net -> net:[4026531962]
lrwxrwxrwx 1 liminghao liminghao 0 Feb 18 21:13 pid -> pid:[4026531836]
lrwxrwxrwx 1 liminghao liminghao 0 Feb 18 21:13 user -> user:[4026531837]
lrwxrwxrwx 1 liminghao liminghao 0 Feb 18 21:13 uts -> uts:[4026531838]
```

可以看出uts namespace编号是一致，表示共用同一个namespace
