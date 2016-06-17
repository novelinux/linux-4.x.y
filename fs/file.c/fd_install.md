fd_install
========================================

在控制权转回用户进程、返回文件描述符之前，fd_install必须将file实例放置到进程
task_struct的files->fd数组中。

path: fs/file.c
```
void fd_install(unsigned int fd, struct file *file)
{
    __fd_install(current->files, fd, file);
}

EXPORT_SYMBOL(fd_install);
```

__fd_install
----------------------------------------

https://github.com/novelinux/linux-4.x.y/blob/master/fs/__fd_install.md
