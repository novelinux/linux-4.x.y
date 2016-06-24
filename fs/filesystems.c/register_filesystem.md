register_filesystem
========================================

在文件系统注册到内核时，文件系统是编译为模块，或者持久编译到内核中，都没有差别。
如果不考虑注册的时间（持久编译到内核的文件系统在启动时注册，模块化文件系统在相关
模块载入内核时注册），在两种情况下所用的技术方法是同样的。

该函数的结构非常简单。所有文件系统都保存在一个（单）链表中，各个文件系统的名称存储为字符串。
在新的文件系统注册到内核时，将逐元素扫描该链表，直至到达链表尾部或找到所需的文件系统。
在后一种情况下，会返回一个适当的错误信息（一个文件系统不能注册两次）；否则，将描述新文件系统的
对象置于链表末尾，这样就完成了向内核的注册。

Arguments
----------------------------------------

path: fs/filesystems.c
```
/**
 *    register_filesystem - register a new filesystem
 *    @fs: the file system structure
 *
 *    Adds the file system passed to the list of file systems the kernel
 *    is aware of for mount and other syscalls. Returns 0 on success,
 *    or a negative errno code on an error.
 *
 *    The &struct file_system_type that is passed is linked into the kernel
 *    structures and must not be freed until the file system has been
 *    unregistered.
 */

int register_filesystem(struct file_system_type * fs)
{
    int res = 0;
    struct file_system_type ** p;

    BUG_ON(strchr(fs->name, '.'));
    if (fs->next)
        return -EBUSY;
    write_lock(&file_systems_lock);
```

find_filesystem
----------------------------------------

```
    p = find_filesystem(fs->name, strlen(fs->name));
    if (*p)
        res = -EBUSY;
    else
        *p = fs;
    write_unlock(&file_systems_lock);
    return res;
}

EXPORT_SYMBOL(register_filesystem);
```

https://github.com/novelinux/linux-4.x.y/blob/master/fs/filesystems.c/find_filesystem.md
