do_execveat_common
========================================

Arguments
----------------------------------------

path: fs/exec.c
```
/*
 * sys_execve() executes a new program.
 */
static int do_execveat_common(int fd, struct filename *filename,
                  struct user_arg_ptr argv,
                  struct user_arg_ptr envp,
                  int flags)
{
    char *pathbuf = NULL;
    struct linux_binprm *bprm;
    struct file *file;
    struct files_struct *displaced;
    int retval;

    if (IS_ERR(filename))
        return PTR_ERR(filename);

    /*
     * We move the actual failure in case of RLIMIT_NPROC excess from
     * set*uid() to execve() because too many poorly written programs
     * don't check setuid() return code.  Here we additionally recheck
     * whether NPROC limit is still exceeded.
     */
    if ((current->flags & PF_NPROC_EXCEEDED) &&
        atomic_read(&current_user()->processes) > rlimit(RLIMIT_NPROC)) {
        retval = -EAGAIN;
        goto out_ret;
    }

    /* We're below the limit (still or again), so we don't want to make
     * further execve() calls fail. */
    current->flags &= ~PF_NPROC_EXCEEDED;
```

unshare_files
----------------------------------------

```
    retval = unshare_files(&displaced);
    if (retval)
        goto out_ret;

    // 为linux_binprm分配内存空间
    retval = -ENOMEM;
    bprm = kzalloc(sizeof(*bprm), GFP_KERNEL);
    if (!bprm)
        goto out_files;
```

prepare_bprm_creds
----------------------------------------

```
    retval = prepare_bprm_creds(bprm);
    if (retval)
        goto out_free;
```

https://github.com/novelinux/linux-4.x.y/tree/master/fs/exec.c/prepare_bprm_creds.md

check_unsafe_exec
----------------------------------------

```
    check_unsafe_exec(bprm);
    current->in_execve = 1;
```

do_open_execat
----------------------------------------

```
    file = do_open_execat(fd, filename, flags);
    retval = PTR_ERR(file);
    if (IS_ERR(file))
        goto out_unmark;
```

调用do_open_execat函数打开进程的可执行文件并返回struct file结构保存到bprm的file成员变量中.

https://github.com/novelinux/linux-4.x.y/tree/master/fs/exec.c/do_open_execat.md

sched_exec
----------------------------------------

```
    sched_exec();
```

选择最小负载的CPU，以执行新程序.

Set bprm (file, filename, interp)
----------------------------------------

```
    bprm->file = file;
    if (fd == AT_FDCWD || filename->name[0] == '/') {
        bprm->filename = filename->name;
    } else {
        if (filename->name[0] == '\0')
            pathbuf = kasprintf(GFP_TEMPORARY, "/dev/fd/%d", fd);
        else
            pathbuf = kasprintf(GFP_TEMPORARY, "/dev/fd/%d/%s",
                        fd, filename->name);
        if (!pathbuf) {
            retval = -ENOMEM;
            goto out_unmark;
        }
        /*
         * Record that a name derived from an O_CLOEXEC fd will be
         * inaccessible after exec. Relies on having exclusive access to
         * current->files (due to unshare_files above).
         */
        if (close_on_exec(fd, rcu_dereference_raw(current->files->fdt)))
            bprm->interp_flags |= BINPRM_FLAGS_PATH_INACCESSIBLE;
        bprm->filename = pathbuf;
    }
    bprm->interp = bprm->filename;
```

bprm_mm_init
----------------------------------------

```
    retval = bprm_mm_init(bprm);
    if (retval)
        goto out_unmark;
```

bprm_mm_init函数调用mm_alloc来生成一个新的mm_struct实例来管理进程的地址空间.

https://github.com/novelinux/linux-4.x.y/tree/master/fs/exec.c/bprm_mm_init.md

Set bprm (argc, envc)
----------------------------------------

```
    bprm->argc = count(argv, MAX_ARG_STRINGS);
    if ((retval = bprm->argc) < 0)
        goto out;

    bprm->envc = count(envp, MAX_ARG_STRINGS);
    if ((retval = bprm->envc) < 0)
        goto out;
```

prepare_binprm
----------------------------------------

```
    retval = prepare_binprm(bprm);
    if (retval < 0)
        goto out;
```

prepare_binprm用于提供一些父进程相关的值(特别数有效UID和GID).

https://github.com/novelinux/linux-4.x.y/tree/master/fs/exec.c/prepare_binprm.md

Set bprm (exec, envp, argv)
----------------------------------------

```
    retval = copy_strings_kernel(1, &bprm->filename, bprm);
    if (retval < 0)
        goto out;

    bprm->exec = bprm->p;
    retval = copy_strings(bprm->envc, envp, bprm);
    if (retval < 0)
        goto out;

    retval = copy_strings(bprm->argc, argv, bprm);
    if (retval < 0)
        goto out;
```

exec_binprm
----------------------------------------

```
    retval = exec_binprm(bprm);
    if (retval < 0)
        goto out;
```

https://github.com/novelinux/linux-4.x.y/tree/master/fs/exec.c/exec_binprm.md

Return
----------------------------------------

```
    /* execve succeeded */
    current->fs->in_exec = 0;
    current->in_execve = 0;
    acct_update_integrals(current);
    task_numa_free(current);
    free_bprm(bprm);
    kfree(pathbuf);
    putname(filename);
    if (displaced)
        put_files_struct(displaced);
    return retval;

out:
    if (bprm->mm) {
        acct_arg_size(bprm, 0);
        mmput(bprm->mm);
    }

out_unmark:
    current->fs->in_exec = 0;
    current->in_execve = 0;

out_free:
    free_bprm(bprm);
    kfree(pathbuf);

out_files:
    if (displaced)
        reset_files_struct(displaced);
out_ret:
    putname(filename);
    return retval;
}
```