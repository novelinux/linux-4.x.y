unshare
========================================

通过unshare()在原先进程上进行namespace隔离, 最后要提的系统调用是unshare()，它跟clone()很像，
不同的是，unshare()运行在原先的进程上，不需要启动一个新进程.

调用unshare()的主要作用就是不启动一个新进程就可以起到隔离的效果，相当于跳出原先的namespace进行
操作。这样，你就可以在原进程进行一些需要隔离的操作。Linux中自带的unshare命令，就是通过unshare()
系统调用实现的.

path: kernel/fork.c
```
/*
 * unshare allows a process to 'unshare' part of the process
 * context which was originally shared using clone.  copy_*
 * functions used by do_fork() cannot be used here directly
 * because they modify an inactive task_struct that is being
 * constructed. Here we are modifying the current, active,
 * task_struct.
 */
SYSCALL_DEFINE1(unshare, unsigned long, unshare_flags)
{
    struct fs_struct *fs, *new_fs = NULL;
    struct files_struct *fd, *new_fd = NULL;
    struct cred *new_cred = NULL;
    struct nsproxy *new_nsproxy = NULL;
    int do_sysvsem = 0;
    int err;

    /*
     * If unsharing a user namespace must also unshare the thread group
     * and unshare the filesystem root and working directories.
     */
    if (unshare_flags & CLONE_NEWUSER)
        unshare_flags |= CLONE_THREAD | CLONE_FS;
    /*
     * If unsharing vm, must also unshare signal handlers.
     */
    if (unshare_flags & CLONE_VM)
        unshare_flags |= CLONE_SIGHAND;
    /*
     * If unsharing a signal handlers, must also unshare the signal queues.
     */
    if (unshare_flags & CLONE_SIGHAND)
        unshare_flags |= CLONE_THREAD;
    /*
     * If unsharing namespace, must also unshare filesystem information.
     */
    if (unshare_flags & CLONE_NEWNS)
        unshare_flags |= CLONE_FS;

    err = check_unshare_flags(unshare_flags);
    if (err)
        goto bad_unshare_out;
    /*
     * CLONE_NEWIPC must also detach from the undolist: after switching
     * to a new ipc namespace, the semaphore arrays from the old
     * namespace are unreachable.
     */
    if (unshare_flags & (CLONE_NEWIPC|CLONE_SYSVSEM))
        do_sysvsem = 1;
    err = unshare_fs(unshare_flags, &new_fs);
    if (err)
        goto bad_unshare_out;
    err = unshare_fd(unshare_flags, &new_fd);
    if (err)
        goto bad_unshare_cleanup_fs;
    err = unshare_userns(unshare_flags, &new_cred);
    if (err)
        goto bad_unshare_cleanup_fd;
    err = unshare_nsproxy_namespaces(unshare_flags, &new_nsproxy,
                     new_cred, new_fs);
    if (err)
        goto bad_unshare_cleanup_cred;

    if (new_fs || new_fd || do_sysvsem || new_cred || new_nsproxy) {
        if (do_sysvsem) {
            /*
             * CLONE_SYSVSEM is equivalent to sys_exit().
             */
            exit_sem(current);
        }
        if (unshare_flags & CLONE_NEWIPC) {
            /* Orphan segments in old ns (see sem above). */
            exit_shm(current);
            shm_init_task(current);
        }

        if (new_nsproxy)
            switch_task_namespaces(current, new_nsproxy);

        task_lock(current);

        if (new_fs) {
            fs = current->fs;
            spin_lock(&fs->lock);
            current->fs = new_fs;
            if (--fs->users)
                new_fs = NULL;
            else
                new_fs = fs;
            spin_unlock(&fs->lock);
        }

        if (new_fd) {
            fd = current->files;
            current->files = new_fd;
            new_fd = fd;
        }

        task_unlock(current);

        if (new_cred) {
            /* Install the new user namespace */
            commit_creds(new_cred);
            new_cred = NULL;
        }
    }

bad_unshare_cleanup_cred:
    if (new_cred)
        put_cred(new_cred);
bad_unshare_cleanup_fd:
    if (new_fd)
        put_files_struct(new_fd);

bad_unshare_cleanup_fs:
    if (new_fs)
        free_fs_struct(new_fs);

bad_unshare_out:
    return err;
}
```