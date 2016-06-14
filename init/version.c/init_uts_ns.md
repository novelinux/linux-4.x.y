init_uts_ns
========================================

path: init/version.c
```
struct uts_namespace init_uts_ns = {
    .kref = {
        .refcount    = ATOMIC_INIT(2),
    },
    .name = {
        .sysname    = UTS_SYSNAME,
        .nodename   = UTS_NODENAME,
        .release    = UTS_RELEASE,
        .version    = UTS_VERSION,
        .machine    = UTS_MACHINE,
        .domainname = UTS_DOMAINNAME,
    },
    .user_ns = &init_user_ns,
    .ns.inum = PROC_UTS_INIT_INO,
#ifdef CONFIG_UTS_NS
    .ns.ops = &utsns_operations,
#endif
};
EXPORT_SYMBOL_GPL(init_uts_ns);
```

相关的预处理器常数在内核中各处定义。例如，UTS_RELEASE在<utsrelease.h>中定义，该文件是编时通过
顶层Makefile动态生成的。请注意，UTS结构的某些部分不能修改。例如，把sysname换成Linux以外的
其他值是没有意义的，但改变机器名是可以的。内核如何创建一个新的UTS命名空间呢？这属于copy_utsname
函数的职责。在某个进程调用fork并通过CLONE_NEWUTS标志指定创建新的UTS命名空间时，则调用该函数。
在这种情况下，会生成先前的uts_namespace实例的一份副本，当前进程的nsproxy实例内部的指针会指向
新的副本。如此而已, 由于在读取或设置UTS属性值时，内核会保证总是操作特定于当前进程的uts_namespace
实例，在当前进程修改UTS属性不会反映到父进程，而父进程的修改也不会传播到子进程。