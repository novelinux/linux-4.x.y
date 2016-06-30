do_execve
========================================

Arguments
----------------------------------------

path: fs/exec.c
```
int do_execve(struct filename *filename,
    const char __user *const __user *__argv,
    const char __user *const __user *__envp)
{
    struct user_arg_ptr argv = { .ptr.native = __argv };
    struct user_arg_ptr envp = { .ptr.native = __envp };
```

* filename: 指向可执行文件的名称;
* argv: 指向传递给进程的参数;
* envp: 指向传递给进程的环境变量;

**注意**: argv和envp都位于虚拟地址空间的用户空间部分，内核在访问用户空间内存是需要多加小心,
而__user注释则允许自动化工具来检测是否所有的相关事宜都处理得当.

do_execveat_common
----------------------------------------

```
    return do_execveat_common(AT_FDCWD, filename, argv, envp, 0);
}
```

https://github.com/novelinux/linux-4.x.y/tree/master/fs/exec.c/do_execveat_common.md
