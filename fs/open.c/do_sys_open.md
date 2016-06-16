do_sys_open
========================================

在内核中，每个打开的文件由一个文件描述符表示，该描述符在特定于
进程的数组中充当位置索引（数组是task_struct->files->fd_array）。
该数组的元素包含了前述的file结构，其中包括每个打开文件的所有
必要信息。

build_open_flags
----------------------------------------

path: fs/open.c
```
long do_sys_open(int dfd, const char __user *filename, int flags, umode_t mode)
{
    struct open_flags op;
    int fd = build_open_flags(flags, mode, &op);
    struct filename *tmp;

    if (fd)
        return fd;
```

https://github.com/novelinux/linux-4.x.y/tree/master/fs/open.c/build_open_flags.md

getname
----------------------------------------

```
    tmp = getname(filename);
    if (IS_ERR(tmp))
        return PTR_ERR(tmp);
```

get_unused_fd_flags
----------------------------------------

```
    fd = get_unused_fd_flags(flags);
```

do_filp_open
----------------------------------------

```
    if (fd >= 0) {
        struct file *f = do_filp_open(dfd, tmp, &op);
```

https://github.com/novelinux/linux-4.x.y/tree/master/fs/namei.c/do_filp_open.md

fd_install
----------------------------------------

在控制权转回用户进程、返回文件描述符之前，fd_install必须将file
实例放置到进程task_struct的files->fd数组中。

```
        if (IS_ERR(f)) {
            put_unused_fd(fd);
            fd = PTR_ERR(f);
        } else {
            fsnotify_open(f);
            fd_install(fd, f);
        }
    }
    putname(tmp);
    return fd;
}
```

https://github.com/novelinux/linux-4.x.y/tree/master/fs/file.c/fd_install.md
