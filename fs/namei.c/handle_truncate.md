handle_truncate
========================================

path: fs/namei.c
```
static int handle_truncate(struct file *filp)
{
    struct path *path = &filp->f_path;
    struct inode *inode = path->dentry->d_inode;
    int error = get_write_access(inode);
    if (error)
        return error;
    /*
     * Refuse to truncate files with mandatory locks held on them.
     */
    error = locks_verify_locked(filp);
    if (!error)
        error = security_path_truncate(path);
    if (!error) {
        error = do_truncate(path->dentry, 0,
                    ATTR_MTIME|ATTR_CTIME|ATTR_OPEN,
                    filp);
    }
    put_write_access(inode);
    return error;
}
```

do_truncate
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/fs/open.c/do_truncate.md
