mount_bdev
========================================

Arguments
----------------------------------------

path: fs/super.c
```
struct dentry *mount_bdev(struct file_system_type *fs_type,
    int flags, const char *dev_name, void *data,
    int (*fill_super)(struct super_block *, void *, int))
{
    struct block_device *bdev;
    struct super_block *s;
    fmode_t mode = FMODE_READ | FMODE_EXCL;
    int error = 0;

    if (!(flags & MS_RDONLY))
        mode |= FMODE_WRITE;
```

blkdev_get_by_path
----------------------------------------

```
    bdev = blkdev_get_by_path(dev_name, mode, fs_type);
    if (IS_ERR(bdev))
        return ERR_CAST(bdev);
```

https://github.com/novelinux/linux-4.x.y/tree/master/fs/block_dev.c/blkdev_get_by_path.md

----------------------------------------

```
    /*
     * once the super is inserted into the list by sget, s_umount
     * will protect the lockfs code from trying to start a snapshot
     * while we are mounting
     */
    mutex_lock(&bdev->bd_fsfreeze_mutex);
    if (bdev->bd_fsfreeze_count > 0) {
        mutex_unlock(&bdev->bd_fsfreeze_mutex);
        error = -EBUSY;
        goto error_bdev;
    }
    s = sget(fs_type, test_bdev_super, set_bdev_super, flags | MS_NOSEC,
         bdev);
    mutex_unlock(&bdev->bd_fsfreeze_mutex);
    if (IS_ERR(s))
        goto error_s;

    if (s->s_root) {
        if ((flags ^ s->s_flags) & MS_RDONLY) {
            deactivate_locked_super(s);
            error = -EBUSY;
            goto error_bdev;
        }

        /*
         * s_umount nests inside bd_mutex during
         * __invalidate_device().  blkdev_put() acquires
         * bd_mutex and can't be called under s_umount.  Drop
         * s_umount temporarily.  This is safe as we're
         * holding an active reference.
         */
        up_write(&s->s_umount);
        blkdev_put(bdev, mode);
        down_write(&s->s_umount);
    } else {
        s->s_mode = mode;
        snprintf(s->s_id, sizeof(s->s_id), "%pg", bdev);
        sb_set_blocksize(s, block_size(bdev));
        error = fill_super(s, data, flags & MS_SILENT ? 1 : 0);
        if (error) {
            deactivate_locked_super(s);
            goto error;
        }

        s->s_flags |= MS_ACTIVE;
        bdev->bd_super = s;
    }

    return dget(s->s_root);

error_s:
    error = PTR_ERR(s);
error_bdev:
    blkdev_put(bdev, mode);
error:
    return ERR_PTR(error);
}
EXPORT_SYMBOL(mount_bdev);
```