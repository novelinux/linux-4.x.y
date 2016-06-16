sys_openat
========================================

path: fs/open.c
```
SYSCALL_DEFINE4(openat, int, dfd, const char __user *, filename, int, flags,
        umode_t, mode)
{
    if (force_o_largefile())
        flags |= O_LARGEFILE;

    return do_sys_open(dfd, filename, flags, mode);
}
```

do_sys_open
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/fs/open.c/do_sys_open.md
