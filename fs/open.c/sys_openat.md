sys_openat
========================================

Code Flow
----------------------------------------

```
sys_openat
 |
 +-> do_sys_open
     |
     +-> getname
     |
     +-> getunused_fd_flags
     |
     +-> do_filp_open
     |   |
     |   +-> set_nameidata
     |   |
     |   +-> path_openat
     |   |   |
     |   |   +-> get_empty_filep
     |   |   |
     |   |   +-> path_init
     |   |   |
     |   |   +-> link_path_walk
     |   |   |
     |   |   +-> do_last
     |   |
     |   +-> restore_nameidata
     |
     +-> fd_install
         |
         +-> __fd_install
```

Arguments
----------------------------------------

path: fs/open.c
```
SYSCALL_DEFINE4(openat, int, dfd, const char __user *, filename, int, flags,
        umode_t, mode)
{
    if (force_o_largefile())
        flags |= O_LARGEFILE;
```

do_sys_open
----------------------------------------

```
    return do_sys_open(dfd, filename, flags, mode);
}
```

https://github.com/novelinux/linux-4.x.y/tree/master/fs/open.c/do_sys_open.md
