__fcheck_files
========================================

path: include/linux/fdtable.h
```
/*
 * The caller must ensure that fd table isn't shared or hold rcu or file lock
 */
static inline struct file *__fcheck_files(struct files_struct *files, unsigned int fd)
{
    struct fdtable *fdt = rcu_dereference_raw(files->fdt);

    if (fd < fdt->max_fds)
        return rcu_dereference_raw(fdt->fd[fd]);
    return NULL;
}
```