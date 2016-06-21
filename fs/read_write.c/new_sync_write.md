new_sync_write
========================================

Arguments
----------------------------------------

path: fs/read_write.c
```
static ssize_t new_sync_write(struct file *filp, const char __user *buf, size_t len, loff_t *ppos)
{
```

Variable
----------------------------------------

### struct iovec

```
    struct iovec iov = { .iov_base = (void __user *)buf, .iov_len = len };
```

https://github.com/novelinux/linux-4.x.y/blob/master/include/uapi/linux/uio.h/struct_iovec.md

### struct kiocb

```
    struct kiocb kiocb;
```

https://github.com/novelinux/linux-4.x.y/blob/master/include/linux/fs.h/struct_kiocb.md

### struct iov_iter

```
    struct iov_iter iter;
    ssize_t ret;
```

https://github.com/novelinux/linux-4.x.y/blob/master/include/linux/uio.h/struct_iov_iter.md

init_sync_kiocb
----------------------------------------

```
    init_sync_kiocb(&kiocb, filp);
    kiocb.ki_pos = *ppos;
```

https://github.com/novelinux/linux-4.x.y/blob/master/include/linux/fs.h/init_sync_kiocb.md

iov_iter_init
----------------------------------------

```
    iov_iter_init(&iter, WRITE, &iov, 1, len);
```

https://github.com/novelinux/linux-4.x.y/blob/master/lib/iov_iter.c/iov_iter_init.md

file->f_op->write_iter
----------------------------------------

```
    ret = filp->f_op->write_iter(&kiocb, &iter);
    BUG_ON(ret == -EIOCBQUEUED);
    if (ret > 0)
        *ppos = kiocb.ki_pos;
    return ret;
}
```

### EXT4

https://github.com/novelinux/linux-4.x.y/blob/master/fs/ext4/file.c/ext4_file_operations.md
