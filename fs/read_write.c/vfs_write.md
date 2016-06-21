vfs_write
========================================

Arguments
----------------------------------------

path: fs/read_write.c
```
ssize_t vfs_write(struct file *file, const char __user *buf, size_t count, loff_t *pos)
{
    ssize_t ret;

    if (!(file->f_mode & FMODE_WRITE))
        return -EBADF;
    if (!(file->f_mode & FMODE_CAN_WRITE))
        return -EINVAL;
    if (unlikely(!access_ok(VERIFY_READ, buf, count)))
        return -EFAULT;
```

rw_verify_area
----------------------------------------

```
    ret = rw_verify_area(WRITE, file, pos, count);
```

__vfs_write
----------------------------------------

```
    if (ret >= 0) {
        count = ret;
        file_start_write(file);
        ret = __vfs_write(file, buf, count, pos);
        if (ret > 0) {
            fsnotify_modify(file);
            add_wchar(current, ret);
        }
        inc_syscw(current);
        file_end_write(file);
    }

    return ret;
}

EXPORT_SYMBOL(vfs_write);
```

https://github.com/novelinux/linux-4.x.y/blob/master/fs/read_write.c/__vfs_write.md
