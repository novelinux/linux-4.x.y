may_open
========================================

path: fs/namei.c
```
static int may_open(struct path *path, int acc_mode, int flag)
{
    struct dentry *dentry = path->dentry;
    struct inode *inode = dentry->d_inode;
    int error;

    if (!inode)
        return -ENOENT;

    switch (inode->i_mode & S_IFMT) {
    case S_IFLNK:
        return -ELOOP;
    case S_IFDIR:
        if (acc_mode & MAY_WRITE)
            return -EISDIR;
        break;
    case S_IFBLK:
    case S_IFCHR:
        if (path->mnt->mnt_flags & MNT_NODEV)
            return -EACCES;
        /*FALLTHRU*/
    case S_IFIFO:
    case S_IFSOCK:
        flag &= ~O_TRUNC;
        break;
    }

    error = inode_permission(inode, MAY_OPEN | acc_mode);
    if (error)
        return error;

    /*
     * An append-only file must be opened in append mode for writing.
     */
    if (IS_APPEND(inode)) {
        if  ((flag & O_ACCMODE) != O_RDONLY && !(flag & O_APPEND))
            return -EPERM;
        if (flag & O_TRUNC)
            return -EPERM;
    }

    /* O_NOATIME can only be set by the owner or superuser */
    if (flag & O_NOATIME && !inode_owner_or_capable(inode))
        return -EPERM;

    return 0;
}
```