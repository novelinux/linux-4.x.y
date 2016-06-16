__fd_install
========================================

comments
----------------------------------------

path: fs/file.c
```
/*
 * Install a file pointer in the fd array.
 *
 * The VFS is full of places where we drop the files lock between
 * setting the open_fds bitmap and installing the file in the file
 * array.  At any such point, we are vulnerable to a dup2() race
 * installing a file in the array before us.  We need to detect this and
 * fput() the struct file we are about to overwrite in this case.
 *
 * It should never happen - if we allow dup2() do it, _really_ bad things
 * will follow.
 *
 * NOTE: __fd_install() variant is really, really low-level; don't
 * use it unless you are forced to by truly lousy API shoved down
 * your throat.  'files' *MUST* be either current->files or obtained
 * by get_files_struct(current) done by whoever had given it to you,
 * or really bad things will happen.  Normally you want to use
 * fd_install() instead.
 */
```

Arguments
----------------------------------------

```
void __fd_install(struct files_struct *files, unsigned int fd,
        struct file *file)
{
    struct fdtable *fdt;

    might_sleep();
    rcu_read_lock_sched();

    while (unlikely(files->resize_in_progress)) {
        rcu_read_unlock_sched();
        wait_event(files->resize_wait, !files->resize_in_progress);
        rcu_read_lock_sched();
    }
```

rcu_dereference_sched
----------------------------------------

```
    /* coupled with smp_wmb() in expand_fdtable() */
    smp_rmb();
    fdt = rcu_dereference_sched(files->fdt);
    BUG_ON(fdt->fd[fd] != NULL);
    rcu_assign_pointer(fdt->fd[fd], file);
    rcu_read_unlock_sched();
}
```
