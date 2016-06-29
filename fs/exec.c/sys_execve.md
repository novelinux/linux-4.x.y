execve
========================================

path: fs/exec.c
```
SYSCALL_DEFINE3(execve,
        const char __user *, filename,
        const char __user *const __user *, argv,
        const char __user *const __user *, envp)
{
    return do_execve(getname(filename), argv, envp);
}
```

do_execve
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/fs/exec.c/do_execve.md
