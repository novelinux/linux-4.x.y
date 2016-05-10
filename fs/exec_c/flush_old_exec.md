flush_old_exec
========================================

Source
----------------------------------------

path: fs/exec.c
```
int flush_old_exec(struct linux_binprm * bprm)
{
    int retval;

    /*
     * Make sure we have a private signal table and that
     * we are unassociated from the previous thread group.
     */
    retval = de_thread(current);
    if (retval)
        goto out;

    set_mm_exe_file(bprm->mm, bprm->file);
    /*
     * Release all of the old mmap stuff
     */
    acct_arg_size(bprm, 0);
    retval = exec_mmap(bprm->mm);
    if (retval)
        goto out;

    bprm->mm = NULL;        /* We're using it now */

    set_fs(USER_DS);
    current->flags &= ~(PF_RANDOMIZE | PF_FORKNOEXEC | PF_KTHREAD |
                    PF_NOFREEZE | PF_NO_SETAFFINITY);
    flush_thread();
    current->personality &= ~bprm->per_clear;

    return 0;

out:
    return retval;
}
EXPORT_SYMBOL(flush_old_exec);
```

de_thread
----------------------------------------

https://github.com/leeminghao/doc-linux/tree/master/4.x.y/fs/exec_c/de_thread.md

set_mm_exe_file
----------------------------------------

https://github.com/leeminghao/doc-linux/tree/master/4.x.y/kernel/fork/set_mm_exe_file.md

acct_arg_size
----------------------------------------

https://github.com/leeminghao/doc-linux/tree/master/4.x.y/fs/exec_c/acct_arg_size.md

exec_mmap
-----------------------------------------

https://github.com/leeminghao/doc-linux/tree/master/4.x.y/fs/exec_c/exec_mmap.md