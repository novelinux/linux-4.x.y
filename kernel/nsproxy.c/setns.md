setns
========================================

在进程都结束的情况下，也可以通过挂载的形式把namespace保留下来，保留namespace的目的自然是为以后
有进程加入做准备。通过setns()系统调用，你的进程从原先的namespace加入我们准备好的新namespace.

Arguments
----------------------------------------

path: kernel/nsproxy.c
```
SYSCALL_DEFINE2(setns, int, fd, int, nstype)
{
```

* fd

表示我们要加入的namespace的文件描述符。上文已经提到，它是一个指向/proc/[pid]/ns目录的
文件描述符，可以通过直接打开该目录下的链接或者打开一个挂载了该目录下链接的文件得到。

* nstype

让调用者可以去检查fd指向的namespace类型是否符合我们实际的要求。如果填0表示不检查

```
    struct task_struct *tsk = current;
    struct nsproxy *new_nsproxy;
    struct file *file;
    struct ns_common *ns;
    int err;

    file = proc_ns_fget(fd);
    if (IS_ERR(file))
        return PTR_ERR(file);

    err = -EINVAL;
    ns = get_proc_ns(file_inode(file));
    if (nstype && (ns->ops->type != nstype))
        goto out;

    new_nsproxy = create_new_namespaces(0, tsk, current_user_ns(), tsk->fs);
    if (IS_ERR(new_nsproxy)) {
        err = PTR_ERR(new_nsproxy);
        goto out;
    }

    err = ns->ops->install(new_nsproxy, ns);
    if (err) {
        free_nsproxy(new_nsproxy);
        goto out;
    }
    switch_task_namespaces(tsk, new_nsproxy);
out:
    fput(file);
    return err;
}
```

为了把我们创建的namespace利用起来，我们需要引入execve()系列函数，这个函数可以执行用户命令，
最常用的就是调用/bin/bash并接受参数，运行起一个shell，用法如下。

```
fd = open(argv[1], O_RDONLY);   /* 获取namespace文件描述符 */
setns(fd, 0);                   /* 加入新的namespace */
execvp(argv[2], &argv[2]);      /* 执行程序 */
```

假设编译后的程序名称为setns。

```
# ./setns ~/uts /bin/bash   # ~/uts 是绑定的/proc/27514/ns/uts
```

至此，你就可以在新的命名空间中执行shell命令了，在下文中会多次使用这种方式来演示隔离的效果。
