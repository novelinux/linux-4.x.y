UTS namespace
========================================


初始设置保存在init_uts_ns中：

path: init/version.c

```
struct uts_namespace init_uts_ns = {
	.kref = {
		.refcount	= ATOMIC_INIT(2),
	},
	.name = {
		.sysname	= UTS_SYSNAME,
		.nodename	= UTS_NODENAME,
		.release	= UTS_RELEASE,
		.version	= UTS_VERSION,
		.machine	= UTS_MACHINE,
		.domainname	= UTS_DOMAINNAME,
	},
	.user_ns = &init_user_ns,
	.ns.inum = PROC_UTS_INIT_INO,
#ifdef CONFIG_UTS_NS
	.ns.ops = &utsns_operations,
#endif
};
```

相关的预处理器常数在内核中各处定义。例如，UTS_RELEASE在<utsrelease.h>中定义，该文件是编时通过
顶层Makefile动态生成的。请注意，UTS结构的某些部分不能修改。例如，把sysname换成Linux以外的
其他值是没有意义的，但改变机器名是可以的。内核如何创建一个新的UTS命名空间呢？这属于copy_ut-sname
函数的职责。在某个进程调用fork并通过CLONE_NEWUTS标志指定创建新的UTS命名空间时，则调用该函数。
在这种情况下，会生成先前的uts_namespace实例的一份副本，当前进程的nsproxy实例内部的指针会指向
新的副本。如此而已!由于在读取或设置UTS属性值时，内核会保证总是操作特定于当前进程的uts_namespace
实例，在当前进程修改UTS属性不会反映到父进程，而父进程的修改也不会传播到子进程。

实例
----------------------------------------

path: src/uts.c
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

编译并运行:

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

不加CLONE_NEWUTS参数运行上述代码，发现主机名也变了，输入exit以后主机名也会变回来，似乎没什么区别。
实际上不加CLONE_NEWUTS参数进行隔离而使用sethostname已经把宿主机的主机名改掉了。你看到exit退出后
还原只是因为bash只在刚登录的时候读取一次UTS，当你重新登陆或者使用uname命令进行查看时，就会发现
产生了变化。

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