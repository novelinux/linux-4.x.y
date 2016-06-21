__vfs_write
========================================

path: fs/read_write.c
```
ssize_t __vfs_write(struct file *file, const char __user *p, size_t count,
            loff_t *pos)
{
    if (file->f_op->write)
        return file->f_op->write(file, p, count, pos);
    else if (file->f_op->write_iter)
        return new_sync_write(file, p, count, pos);
    else
        return -EINVAL;
}
EXPORT_SYMBOL(__vfs_write);
```

file->f_op->write
----------------------------------------

### EXT4

https://github.com/novelinux/linux-4.x.y/blob/master/fs/ext4/file.c/ext4_file_operations.md

new_sync_write
----------------------------------------

https://github.com/novelinux/linux-4.x.y/blob/master/fs/read_write.c/new_sync_write.md
