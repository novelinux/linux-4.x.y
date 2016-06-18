lookup_open
========================================

comments
----------------------------------------

path: fs/namei.c
```
/*
 * Look up and maybe create and open the last component.
 *
 * Must be called with i_mutex held on parent.
 *
 * Returns 0 if the file was successfully atomically created (if necessary) and
 * opened.  In this case the file will be returned attached to @file.
 *
 * Returns 1 if the file was not completely opened at this time, though lookups
 * and creations will have been performed and the dentry returned in @path will
 * be positive upon return if O_CREAT was specified.  If O_CREAT wasn't
 * specified then a negative dentry may be returned.
 *
 * An error code is returned otherwise.
 *
 * FILE_CREATE will be set in @*opened if the dentry was created and will be
 * cleared otherwise prior to returning.
 */
```

Arguments
----------------------------------------

```
static int lookup_open(struct nameidata *nd, struct path *path,
            struct file *file,
            const struct open_flags *op,
            bool got_write, int *opened)
{
    struct dentry *dir = nd->path.dentry;
    struct inode *dir_inode = dir->d_inode;
    struct dentry *dentry;
    int error;
    bool need_lookup;
```

lookup_dcache
----------------------------------------

```
    *opened &= ~FILE_CREATED;
    dentry = lookup_dcache(&nd->last, dir, nd->flags, &need_lookup);
    if (IS_ERR(dentry))
        return PTR_ERR(dentry);

    /* Cached positive dentry: will open in f_op->open */
    if (!need_lookup && dentry->d_inode)
        goto out_no_open;

    if ((nd->flags & LOOKUP_OPEN) && dir_inode->i_op->atomic_open) {
        return atomic_open(nd, dentry, path, file, op, got_write,
                   need_lookup, opened);
    }
```

https://github.com/novelinux/linux-4.x.y/tree/master/fs/namei.c/lookup_dcache.md

lookup_real
----------------------------------------

```
    if (need_lookup) {
        BUG_ON(dentry->d_inode);

        dentry = lookup_real(dir_inode, dentry, nd->flags);
        if (IS_ERR(dentry))
            return PTR_ERR(dentry);
    }
```

vfs_create
----------------------------------------

```
    /* Negative dentry, just create the file */
    if (!dentry->d_inode && (op->open_flag & O_CREAT)) {
        umode_t mode = op->mode;
        if (!IS_POSIXACL(dir->d_inode))
            mode &= ~current_umask();
        /*
         * This write is needed to ensure that a
         * rw->ro transition does not occur between
         * the time when the file is created and when
         * a permanent write count is taken through
         * the 'struct file' in finish_open().
         */
        if (!got_write) {
            error = -EROFS;
            goto out_dput;
        }
        *opened |= FILE_CREATED;
        error = security_path_mknod(&nd->path, dentry, mode, 0);
        if (error)
            goto out_dput;
        error = vfs_create(dir->d_inode, dentry, mode,
                   nd->flags & LOOKUP_EXCL);
        if (error)
            goto out_dput;
    }
```

https://github.com/novelinux/linux-4.x.y/tree/master/fs/namei.c/vfs_create.md

out_no_open
----------------------------------------

```
out_no_open:
    path->dentry = dentry;
    path->mnt = nd->path.mnt;
    return 1;

out_dput:
    dput(dentry);
    return error;
}
```
