path_init
========================================

内核使用nameidata实例规定查找的起点。如果名称以/开始，则使用当前根目录
的dentry和vfsmount实例（要注意，必须考虑到chroot的效应）；否则，从当前进程的
task_struct获得当前工作目录的数据。

首先将nameidata实例path的mnt和dentry成员设置为根目录或工作目录对应的数据项。

Arguments
----------------------------------------

path: fs/namei.c
```
static const char *path_init(struct nameidata *nd, unsigned flags)
{
    int retval = 0;
    const char *s = nd->name->name;
```

Absolute Path
----------------------------------------

```
    nd->last_type = LAST_ROOT; /* if there are only slashes... */
    nd->flags = flags | LOOKUP_JUMPED | LOOKUP_PARENT;
    nd->depth = 0;
    nd->total_link_count = 0;
    if (flags & LOOKUP_ROOT) {
        struct dentry *root = nd->root.dentry;
        struct inode *inode = root->d_inode;
        if (*s) {
            if (!d_can_lookup(root))
                return ERR_PTR(-ENOTDIR);
            retval = inode_permission(inode, MAY_EXEC);
            if (retval)
                return ERR_PTR(retval);
        }
        nd->path = nd->root;
        nd->inode = inode;
        if (flags & LOOKUP_RCU) {
            rcu_read_lock();
            nd->seq = __read_seqcount_begin(&nd->path.dentry->d_seq);
            nd->root_seq = nd->seq;
            nd->m_seq = read_seqbegin(&mount_lock);
        } else {
            path_get(&nd->path);
        }
        return s;
    }

    nd->root.mnt = NULL;

    nd->m_seq = read_seqbegin(&mount_lock);
    if (*s == '/') {
        if (flags & LOOKUP_RCU) {
            rcu_read_lock();
            set_root_rcu(nd);
            nd->seq = nd->root_seq;
        } else {
            set_root(nd);
            path_get(&nd->root);
        }
        nd->path = nd->root;
```

### set_root

https://github.com/novelinux/linux-4.x.y/blob/master/fs/namei.c/set_root.md

Relative Path
----------------------------------------

```
    } else if (nd->dfd == AT_FDCWD) {
        if (flags & LOOKUP_RCU) {
            struct fs_struct *fs = current->fs;
            unsigned seq;

            rcu_read_lock();

            do {
                seq = read_seqcount_begin(&fs->seq);
                nd->path = fs->pwd;
                nd->seq = __read_seqcount_begin(&nd->path.dentry->d_seq);
            } while (read_seqcount_retry(&fs->seq, seq));
        } else {
            get_fs_pwd(current->fs, &nd->path);
        }
    } else {
        /* Caller must check execute permissions on the starting path component */
        struct fd f = fdget_raw(nd->dfd);
        struct dentry *dentry;

        if (!f.file)
            return ERR_PTR(-EBADF);

        dentry = f.file->f_path.dentry;

        if (*s) {
            if (!d_can_lookup(dentry)) {
                fdput(f);
                return ERR_PTR(-ENOTDIR);
            }
        }

        nd->path = f.file->f_path;
        if (flags & LOOKUP_RCU) {
            rcu_read_lock();
            nd->inode = nd->path.dentry->d_inode;
            nd->seq = read_seqcount_begin(&nd->path.dentry->d_seq);
        } else {
            path_get(&nd->path);
            nd->inode = nd->path.dentry->d_inode;
        }
        fdput(f);
        return s;
    }

    nd->inode = nd->path.dentry->d_inode;
    if (!(flags & LOOKUP_RCU))
        return s;
    if (likely(!read_seqcount_retry(&nd->path.dentry->d_seq, nd->seq)))
        return s;
    if (!(nd->flags & LOOKUP_ROOT))
        nd->root.mnt = NULL;
    rcu_read_unlock();
    return ERR_PTR(-ECHILD);
}
```