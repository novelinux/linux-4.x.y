blkdev_get_by_path
========================================

Arguments
----------------------------------------

path: fs/block_dev.c
```
/**
 * blkdev_get_by_path - open a block device by name
 * @path: path to the block device to open
 * @mode: FMODE_* mask
 * @holder: exclusive holder identifier
 *
 * Open the blockdevice described by the device file at @path.  @mode
 * and @holder are identical to blkdev_get().
 *
 * On success, the returned block_device has reference count of one.
 *
 * CONTEXT:
 * Might sleep.
 *
 * RETURNS:
 * Pointer to block_device on success, ERR_PTR(-errno) on failure.
 */
struct block_device *blkdev_get_by_path(const char *path, fmode_t mode,
                    void *holder)
{
    struct block_device *bdev;
    int err;
```

lookup_bdev
----------------------------------------

```
    bdev = lookup_bdev(path);
    if (IS_ERR(bdev))
        return bdev;
```

https://github.com/novelinux/linux-4.x.y/tree/master/fs/block_dev.c/lookup_bdev.md

blkdev_get
----------------------------------------

```
    err = blkdev_get(bdev, mode, holder);
    if (err)
        return ERR_PTR(err);

    if ((mode & FMODE_WRITE) && bdev_read_only(bdev)) {
        blkdev_put(bdev, mode);
        return ERR_PTR(-EACCES);
    }

    return bdev;
}
EXPORT_SYMBOL(blkdev_get_by_path);
```