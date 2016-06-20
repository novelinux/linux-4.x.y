do_last
========================================

do_last用于处理从link_path_walk扫描处理回来的路径分量.

Code Flow
----------------------------------------

```
do_last
 |
 +-> handle_dots (nd->last_type != LAST_NORM)
 |
 +-> lookup_fast (!(open_flag & O_CREAT))
 |
 +-> mnt_want_write (op->open_flag & (O_CREAT | O_TRUNC | O_WRONLY | O_RDWR))
 |
 +-> lookup_open
 |   |
 |   +-> lookup_dcache
 |   |
 |   +-> lookup_real
 |   |
 |   +-> vfs_create
 |
 +-> may_open
 |
 +-> vfs_open
```

Arguments
----------------------------------------

path: fs/namei.c
```
/*
 * Handle the last step of open()
 */
static int do_last(struct nameidata *nd,
           struct file *file, const struct open_flags *op,
           int *opened)
{
    struct dentry *dir = nd->path.dentry;
    int open_flag = op->open_flag;
    bool will_truncate = (open_flag & O_TRUNC) != 0;
    bool got_write = false;
    int acc_mode = op->acc_mode;
    unsigned seq;
    struct inode *inode;
    struct path save_parent = { .dentry = NULL, .mnt = NULL };
    struct path path;
    bool retried = false;
    int error;

    nd->flags &= ~LOOKUP_PARENT;
    nd->flags |= op->intent;
```

handle_dots
----------------------------------------

```
    if (nd->last_type != LAST_NORM) {
        error = handle_dots(nd, nd->last_type);
        if (unlikely(error))
            return error;
        goto finish_open;
    }
```

lookup_fast
----------------------------------------

```
    if (!(open_flag & O_CREAT)) {
        if (nd->last.name[nd->last.len])
            nd->flags |= LOOKUP_FOLLOW | LOOKUP_DIRECTORY;
        /* we _can_ be in RCU mode here */
        error = lookup_fast(nd, &path, &inode, &seq);
        if (likely(!error))
            goto finish_lookup;

        if (error < 0)
            return error;

        BUG_ON(nd->inode != dir->d_inode);
    } else {
        /* create side of things */
        /*
         * This will *only* deal with leaving RCU mode - LOOKUP_JUMPED
         * has been cleared when we got to the last component we are
         * about to look up
         */
        error = complete_walk(nd);
        if (error)
            return error;

        audit_inode(nd->name, dir, LOOKUP_PARENT);
        /* trailing slashes? */
        if (unlikely(nd->last.name[nd->last.len]))
            return -EISDIR;
    }
```

https://github.com/novelinux/linux-4.x.y/blob/master/fs/namei.c/lookup_fast.md

retry_lookup
----------------------------------------

### mnt_want_write

```
retry_lookup:
    if (op->open_flag & (O_CREAT | O_TRUNC | O_WRONLY | O_RDWR)) {
        error = mnt_want_write(nd->path.mnt);
        if (!error)
            got_write = true;
        /*
         * do _not_ fail yet - we might not need that or fail with
         * a different error; let lookup_open() decide; we'll be
         * dropping this one anyway.
         */
    }
    mutex_lock(&dir->d_inode->i_mutex);
```

https://github.com/novelinux/linux-4.x.y/tree/master/fs/namespace.c/mnt_want_write.md

### lookup_open

调用lookup_open来查找对应文件是否已经打开.如果已经已经打开则直接掉转到

```
    error = lookup_open(nd, &path, file, op, got_write, opened);
    mutex_unlock(&dir->d_inode->i_mutex);

    if (error <= 0) {
        if (error)
            goto out;

        if ((*opened & FILE_CREATED) ||
            !S_ISREG(file_inode(file)->i_mode))
            will_truncate = false;

        audit_inode(nd->name, file->f_path.dentry, 0);
        goto opened;
    }
```

https://github.com/novelinux/linux-4.x.y/tree/master/fs/namei.c/lookup_open.md

### goto finish_open_created

```
    if (*opened & FILE_CREATED) {
        /* Don't check for write permission, don't truncate */
        open_flag &= ~O_TRUNC;
        will_truncate = false;
        acc_mode = MAY_OPEN;
        path_to_nameidata(&path, nd);
        goto finish_open_created;
    }
```

### other

```
    /*
     * create/update audit record if it already exists.
     */
    if (d_is_positive(path.dentry))
        audit_inode(nd->name, path.dentry, 0);

    /*
     * If atomic_open() acquired write access it is dropped now due to
     * possible mount and symlink following (this might be optimized away if
     * necessary...)
     */
    if (got_write) {
        mnt_drop_write(nd->path.mnt);
        got_write = false;
    }

    if (unlikely((open_flag & (O_EXCL | O_CREAT)) == (O_EXCL | O_CREAT))) {
        path_to_nameidata(&path, nd);
        return -EEXIST;
    }

    error = follow_managed(&path, nd);
    if (unlikely(error < 0))
        return error;

    BUG_ON(nd->flags & LOOKUP_RCU);
    inode = d_backing_inode(path.dentry);
    seq = 0;    /* out of RCU mode, so the value doesn't matter */
    if (unlikely(d_is_negative(path.dentry))) {
        path_to_nameidata(&path, nd);
        return -ENOENT;
    }
```

finish_lookup
----------------------------------------

```
finish_lookup:
    if (nd->depth)
        put_link(nd);
    error = should_follow_link(nd, &path, nd->flags & LOOKUP_FOLLOW,
                   inode, seq);
    if (unlikely(error))
        return error;

    if (unlikely(d_is_symlink(path.dentry)) && !(open_flag & O_PATH)) {
        path_to_nameidata(&path, nd);
        return -ELOOP;
    }

    if ((nd->flags & LOOKUP_RCU) || nd->path.mnt != path.mnt) {
        path_to_nameidata(&path, nd);
    } else {
        save_parent.dentry = nd->path.dentry;
        save_parent.mnt = mntget(path.mnt);
        nd->path.dentry = path.dentry;

    }
    nd->inode = inode;
    nd->seq = seq;
    /* Why this, you ask?  _Now_ we might have grown LOOKUP_JUMPED... */
```

finish_open
----------------------------------------

```
finish_open:
    error = complete_walk(nd);
    if (error) {
        path_put(&save_parent);
        return error;
    }
    audit_inode(nd->name, nd->path.dentry, 0);
    error = -EISDIR;
    if ((open_flag & O_CREAT) && d_is_dir(nd->path.dentry))
        goto out;
    error = -ENOTDIR;
    if ((nd->flags & LOOKUP_DIRECTORY) && !d_can_lookup(nd->path.dentry))
        goto out;
    if (!d_is_reg(nd->path.dentry))
        will_truncate = false;

    if (will_truncate) {
        error = mnt_want_write(nd->path.mnt);
        if (error)
            goto out;
        got_write = true;
    }
```

finish_open_created
----------------------------------------

### may_open

```
finish_open_created:
    error = may_open(&nd->path, acc_mode, open_flag);
    if (error)
        goto out;

    BUG_ON(*opened & FILE_OPENED); /* once it's opened, it's opened */
```

https://github.com/novelinux/linux-4.x.y/tree/master/fs/namei.c/may_open.md

### vfs_open

```
    error = vfs_open(&nd->path, file, current_cred());
    if (!error) {
        *opened |= FILE_OPENED;
    } else {
        if (error == -EOPENSTALE)
            goto stale_open;
        goto out;
    }
```

https://github.com/novelinux/linux-4.x.y/tree/master/fs/open.c/vfs_open.md

opened
----------------------------------------

```
opened:
    error = open_check_o_direct(file);
    if (error)
        goto exit_fput;
    error = ima_file_check(file, op->acc_mode, *opened);
    if (error)
        goto exit_fput;
```

### handle_truncate

```
    if (will_truncate) {
        error = handle_truncate(file);
        if (error)
            goto exit_fput;
    }
```

https://github.com/novelinux/linux-4.x.y/tree/master/fs/namei.c/handle_truncate.md

out
----------------------------------------

```
out:
    if (got_write)
        mnt_drop_write(nd->path.mnt);
    path_put(&save_parent);
    return error;
```

exit_fput
----------------------------------------

```
exit_fput:
    fput(file);
    goto out;
```

stale_open
----------------------------------------

```
stale_open:
    /* If no saved parent or already retried then can't retry */
    if (!save_parent.dentry || retried)
        goto out;

    BUG_ON(save_parent.dentry != dir);
    path_put(&nd->path);
    nd->path = save_parent;
    nd->inode = dir->d_inode;
    save_parent.mnt = NULL;
    save_parent.dentry = NULL;
    if (got_write) {
        mnt_drop_write(nd->path.mnt);
        got_write = false;
    }
    retried = true;
    goto retry_lookup;
}
```