# lookup_fast

path: fs/namei.c
```
/*
 *  It's more convoluted than I'd like it to be, but... it's still fairly
 *  small and for now I'd prefer to have fast path as straight as possible.
 *  It _is_ time-critical.
 */
static int lookup_fast(struct nameidata *nd,
               struct path *path, struct inode **inode,
               unsigned *seqp)
{
    struct vfsmount *mnt = nd->path.mnt;
    struct dentry *dentry, *parent = nd->path.dentry;
    int need_reval = 1;
    int status = 1;
    int err;

    /*
     * Rename seqlock is not required here because in the off chance
     * of a false negative due to a concurrent rename, we're going to
     * do the non-racy lookup, below.
     */
    if (nd->flags & LOOKUP_RCU) {
        unsigned seq;
        bool negative;
        dentry = __d_lookup_rcu(parent, &nd->last, &seq);
        if (!dentry)
            goto unlazy;

        /*
         * This sequence count validates that the inode matches
         * the dentry name information from lookup.
         */
        *inode = d_backing_inode(dentry);
        negative = d_is_negative(dentry);
        if (read_seqcount_retry(&dentry->d_seq, seq))
            return -ECHILD;

        /*
         * This sequence count validates that the parent had no
         * changes while we did the lookup of the dentry above.
         *
         * The memory barrier in read_seqcount_begin of child is
         *  enough, we can use __read_seqcount_retry here.
         */
        if (__read_seqcount_retry(&parent->d_seq, nd->seq))
            return -ECHILD;

        *seqp = seq;
        if (unlikely(dentry->d_flags & DCACHE_OP_REVALIDATE)) {
            status = d_revalidate(dentry, nd->flags);
            if (unlikely(status <= 0)) {
                if (status != -ECHILD)
                    need_reval = 0;
                goto unlazy;
            }
        }
        /*
         * Note: do negative dentry check after revalidation in
         * case that drops it.
         */
        if (negative)
            return -ENOENT;
        path->mnt = mnt;
        path->dentry = dentry;
        if (likely(__follow_mount_rcu(nd, path, inode, seqp)))
            return 0;
unlazy:
        if (unlazy_walk(nd, dentry, seq))
            return -ECHILD;
```

## __d_lookup

```
    } else {
        dentry = __d_lookup(parent, &nd->last);
    }

    if (unlikely(!dentry))
        goto need_lookup;

    if (unlikely(dentry->d_flags & DCACHE_OP_REVALIDATE) && need_reval)
        status = d_revalidate(dentry, nd->flags);
    if (unlikely(status <= 0)) {
        if (status < 0) {
            dput(dentry);
            return status;
        }
        d_invalidate(dentry);
        dput(dentry);
        goto need_lookup;
    }

    if (unlikely(d_is_negative(dentry))) {
        dput(dentry);
        return -ENOENT;
    }
    path->mnt = mnt;
    path->dentry = dentry;
    err = follow_managed(path, nd);
    if (likely(!err))
        *inode = d_backing_inode(path->dentry);
    return err;

need_lookup:
    return 1;
}
```

https://github.com/novelinux/linux-4.x.y/blob/master/fs/dcache.c/__d_lookup.md
