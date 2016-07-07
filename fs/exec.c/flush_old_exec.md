flush_old_exec
========================================

Arguments
----------------------------------------

path: fs/exec.c
```
int flush_old_exec(struct linux_binprm * bprm)
{
    int retval;
```

de_thread
----------------------------------------

```
    /*
     * Make sure we have a private signal table and that
     * we are unassociated from the previous thread group.
     */
    retval = de_thread(current);
    if (retval)
        goto out;
```

https://github.com/novelinux/linux-4.x.y/tree/master/fs/exec.c/de_thread.md

set_mm_exe_file
----------------------------------------

```
    /*
     * Must be called _before_ exec_mmap() as bprm->mm is
     * not visibile until then. This also enables the update
     * to be lockless.
     */
    set_mm_exe_file(bprm->mm, bprm->file);
```

https://github.com/novelinux/linux-4.x.y/tree/master/kernel/fork.c/set_mm_exe_file.md

acct_arg_size
----------------------------------------

```
    /*
     * Release all of the old mmap stuff
     */
    acct_arg_size(bprm, 0);
```

https://github.com/novelinux/linux-4.x.y/tree/master/fs/exec.c/acct_arg_size.md

exec_mmap
-----------------------------------------

```
    retval = exec_mmap(bprm->mm);
    if (retval)
        goto out;
```

https://github.com/novelinux/linux-4.x.y/tree/master/fs/exec.c/exec_mmap.md

set_fs
----------------------------------------

```
    bprm->mm = NULL;        /* We're using it now */

    set_fs(USER_DS);
    current->flags &= ~(PF_RANDOMIZE | PF_FORKNOEXEC | PF_KTHREAD |
                    PF_NOFREEZE | PF_NO_SETAFFINITY);
```

flush_thread
----------------------------------------

```
    flush_thread();
    current->personality &= ~bprm->per_clear;

    return 0;

out:
    return retval;
}
EXPORT_SYMBOL(flush_old_exec);
```
