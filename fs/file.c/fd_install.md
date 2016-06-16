fd_install
========================================

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
