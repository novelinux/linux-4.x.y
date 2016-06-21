sys_write
========================================

Arguments
----------------------------------------

path: fs/read_write.c
```
SYSCALL_DEFINE3(write, unsigned int, fd, const char __user *, buf,
        size_t, count)
{
```

fdget_pos
----------------------------------------

```
    struct fd f = fdget_pos(fd);
    ssize_t ret = -EBADF;
```

https://github.com/novelinux/linux-4.x.y/blob/master/fs/read_write.c/fdget_pos.md

file_pos_read
----------------------------------------

```
    if (f.file) {
        loff_t pos = file_pos_read(f.file);
```

vfs_write
----------------------------------------

```
        ret = vfs_write(f.file, buf, count, &pos);
```

https://github.com/novelinux/linux-4.x.y/blob/master/fs/read_write.c/vfs_write.md

file_pos_write
----------------------------------------

```
        if (ret >= 0)
            file_pos_write(f.file, pos);
        fdput_pos(f);
    }

    return ret;
}
```