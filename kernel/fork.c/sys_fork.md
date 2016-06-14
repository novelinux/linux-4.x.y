sys_fork
========================================

path: kernel/fork.c
```
#ifdef __ARCH_WANT_SYS_FORK
SYSCALL_DEFINE0(fork)
{
#ifdef CONFIG_MMU
    return _do_fork(SIGCHLD, 0, 0, NULL, NULL, 0);
#else
    /* can not support in nommu mode */
    return -EINVAL;
#endif
}
#endif
```

唯一使用的标志是SIGCHLD。这意味着在子进程终止后发送SIGCHLD信号通知父进程。最初，父子进程的
栈地址相同。但如果操作栈地址并写入数据，则COW机制会为每个进程分别创建一个栈副本。如果do_fork成功，
则新建进程的PID作为系统调用的结果返回，否则返回错误码(负值)。

SYSCALL_DEFINE0
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/syscalls.h/SYSCALL_DEFINE.md

_do_fork
----------------------------------------

sys_fork函数最终是调用_do_fork来实现一个进程的创建:

https://github.com/novelinux/linux-4.x.y/tree/master/kernel/fork.c/_do_fork.md
