do_execve
========================================

通过用新代码替换现有进程，即可启动新程序. Linux提供的execve即可用于该目的

参数
----------------------------------------

path: fs/exec.c
```
int do_execve(struct filename *filename,
    const char __user *const __user *__argv,
    const char __user *const __user *__envp)
{
        struct user_arg_ptr argv = { .ptr.native = __argv };
        struct user_arg_ptr envp = { .ptr.native = __envp };
        return do_execveat_common(AT_FDCWD, filename, argv, envp, 0);
}
```

* filename: 指向可执行文件的名称;
* argv: 指向传递给进程的参数;
* envp: 指向传递给进程的环境变量;

**注意**: argv和envp都位于虚拟地址空间的用户空间部分，内核在访问用户空间内存是需要多加小心,
而__user注释则允许自动化工具来检测是否所有的相关事宜都处理得当.

接下来调用do_execveat_common函数来进行处理

do_execveat_common
----------------------------------------

检查和初始化工作
----------------------------------------

* 检查程序文件名称是否正确;
* 检查进程的数量限制;
* 为bprm(struct linux_binprm)调用kzalloc分配内存;

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

为linux_binprm分配内存空间
----------------------------------------

```
    retval = unshare_files(&displaced);
    if (retval)
        goto out_ret;

    retval = -ENOMEM;
    bprm = kzalloc(sizeof(*bprm), GFP_KERNEL);
    if (!bprm)
        goto out_files;
```

linux_binprm结构定义如下所示:

https://github.com/leeminghao/doc-linux/tree/master/4.x.y/include/linux/binfmts.h/binfmts.md

3.prepare_bprm_creds
----------------------------------------

```
    retval = prepare_bprm_creds(bprm);
    if (retval)
        goto out_free;
```

prepare_bprm_creds用于准备可执行credential. 具体实现如下:

https://github.com/leeminghao/doc-linux/tree/master/4.x.y/fs/exec_c/prepare_bprm_creds.md

4.do_open_execat
----------------------------------------

```
    check_unsafe_exec(bprm);
    current->in_execve = 1;

    file = do_open_execat(fd, filename, flags);
    retval = PTR_ERR(file);
    if (IS_ERR(file))
        goto out_unmark;
```

调用do_open_execat函数打开进程的可执行文件并返回struct file结构保存到bprm的file成员变量中.
具体实现如下所示:

https://github.com/leeminghao/doc-linux/tree/master/4.x.y/fs/exec_c/do_open_execat.md

5.sched_exec
----------------------------------------

```
    sched_exec();
```

sched_exec

选择最小负载的CPU，以执行新程序.

path: include/linux/sched.h
```
/* sched_exec is called by processes performing an exec */
#ifdef CONFIG_SMP
extern void sched_exec(void);
#else
#define sched_exec()   {}
#endif
```

6.bprm_mm_init
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

    retval = bprm_mm_init(bprm);
    if (retval)
        goto out_unmark;

    bprm->argc = count(argv, MAX_ARG_STRINGS);
    if ((retval = bprm->argc) < 0)
        goto out;

    bprm->envc = count(envp, MAX_ARG_STRINGS);
    if ((retval = bprm->envc) < 0)
        goto out;
```

bprm_mm_init函数调用mm_alloc来生成一个新的mm_struct实例来管理进程的地址空间.
具体实现如下所示:

https://github.com/leeminghao/doc-linux/tree/master/4.x.y/fs/exec_c/bprm_mm_init.md

7.prepare_binprm
----------------------------------------

```
    retval = prepare_binprm(bprm);
    if (retval < 0)
        goto out;

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

prepare_binprm用于提供一些父进程相关的值(特别数有效UID和GID).

https://github.com/leeminghao/doc-linux/tree/master/4.x.y/fs/exec_c/prepare_binprm.md

8.exec_binprm
----------------------------------------

```
    retval = exec_binprm(bprm);
    if (retval < 0)
        goto out;

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
    ...
}
```

https://github.com/leeminghao/doc-linux/tree/master/4.x.y/fs/exec_c/exec_binprm.md
