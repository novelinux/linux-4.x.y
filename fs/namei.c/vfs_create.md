vfs_create
========================================

Arguments
----------------------------------------

path: fs/namei.c
```
int vfs_create(struct inode *dir, struct dentry *dentry, umode_t mode,
        bool want_excl)
{
```

may_create
----------------------------------------

```
    int error = may_create(dir, dentry);
    if (error)
        return error;

    if (!dir->i_op->create)
        return -EACCES;    /* shouldn't it be ENOSYS? */
    mode &= S_IALLUGO;
    mode |= S_IFREG;
    error = security_inode_create(dir, dentry, mode);
    if (error)
        return error;
```

https://github.com/novelinux/linux-4.x.y/blob/master/fs/namei.c/may_create.md

i_op->create
----------------------------------------

```
    error = dir->i_op->create(dir, dentry, mode, want_excl);
    if (!error)
        fsnotify_create(dir, dentry);
    return error;
}
EXPORT_SYMBOL(vfs_create);
```

### ext4

https://github.com/novelinux/linux-4.x.y/blob/master/fs/ext4/namei.c/ext4_dir_inode_operations.md
