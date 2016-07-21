lookup_bdev
========================================

path: fs/block_dev.c
```
/**
 * lookup_bdev  - lookup a struct block_device by name
 * @pathname:    special file representing the block device
 *
 * Get a reference to the blockdevice at @pathname in the current
 * namespace if possible and return it.  Return ERR_PTR(error)
 * otherwise.
 */
struct block_device *lookup_bdev(const char *pathname)
{
    struct block_device *bdev;
    struct inode *inode;
    struct path path;
    int error;

    if (!pathname || !*pathname)
        return ERR_PTR(-EINVAL);
```

kern_path
----------------------------------------

```
    error = kern_path(pathname, LOOKUP_FOLLOW, &path);
    if (error)
        return ERR_PTR(error);
```

https://github.com/novelinux/linux-4.x.y/tree/master/fs/namei.c/kern_path.md

d_backing_inode
----------------------------------------

```
    inode = d_backing_inode(path.dentry);
    error = -ENOTBLK;
    if (!S_ISBLK(inode->i_mode))
        goto fail;
    error = -EACCES;
    if (path.mnt->mnt_flags & MNT_NODEV)
        goto fail;
    error = -ENOMEM;
```

bd_acquire
----------------------------------------

```
    bdev = bd_acquire(inode);
    if (!bdev)
        goto fail;
```

```
out:
    path_put(&path);
    return bdev;
fail:
    bdev = ERR_PTR(error);
    goto out;
}
EXPORT_SYMBOL(lookup_bdev);
```