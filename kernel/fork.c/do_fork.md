do_fork
========================================

path: kernel/fork.c
```
#ifndef CONFIG_HAVE_COPY_THREAD_TLS
/* For compatibility with architectures that call do_fork directly rather than
 * using the syscall entry points below. */
long do_fork(unsigned long clone_flags,
          unsigned long stack_start,
          unsigned long stack_size,
          int __user *parent_tidptr,
          int __user *child_tidptr)
{
    return _do_fork(clone_flags, stack_start, stack_size,
            parent_tidptr, child_tidptr, 0);
}
#endif
```

_do_fork
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/kernel/fork.c/_do_fork.md
