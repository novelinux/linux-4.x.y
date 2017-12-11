# lookup_fast

首先调用 __d_lookup_rcu 在内存中的某个散列表里通过字符串比较查找目标 dentry，
如果找到了就返回该 dentry；如果没找到就需要跳转到 unlazy 标号处，在这里会使用
unlazy_walk 就地将查找模式切换到 ref-walk.
如果顺利找到了目标 dentry 则还需要进行一系列的检查, 确保在我们做读取操作的期间没有人
对这些结构进行改动。然后就是更新临时变量 path，为啥不更新 nd 呢？别忘了 nd 是很有脾气的，
挂载点和符号链接人家都看不上，非真正目录不嫁。而这个时候还不知道这个目标是不是一个挂载点，
如果是挂载点则还需要沿着被挂载的 mount 结构走到真正的目标上；退一步来说，就算这个目标不是挂载点，
但它要是具备自动挂载特性呢；再退一步来说，它是不是符号链接我们也不知道，所以现在先不忙着更新 nd。
在 rcu-walk 模式下是不会启动 lookup_slow 的。

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
