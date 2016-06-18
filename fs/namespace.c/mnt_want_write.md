mnt_want_write
========================================

path: fs/namespace.c
```
/**
 * mnt_want_write - get write access to a mount
 * @m: the mount on which to take a write
 *
 * This tells the low-level filesystem that a write is about to be performed to
 * it, and makes sure that writes are allowed (mount is read-write, filesystem
 * is not frozen) before returning success.  When the write operation is
 * finished, mnt_drop_write() must be called.  This is effectively a refcount.
 */
int mnt_want_write(struct vfsmount *m)
{
    int ret;

    sb_start_write(m->mnt_sb);
    ret = __mnt_want_write(m);
    if (ret)
        sb_end_write(m->mnt_sb);
    return ret;
}
EXPORT_SYMBOL_GPL(mnt_want_write);
```

__mnt_want_write
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/fs/namespace.c/__mnt_want_write.md
