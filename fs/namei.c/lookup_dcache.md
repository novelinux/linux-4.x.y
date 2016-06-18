lookup_dcache
========================================

path: fs/namei.c
```
/*
 * This looks up the name in dcache, possibly revalidates the old dentry and
 * allocates a new one if not found or not valid.  In the need_lookup argument
 * returns whether i_op->lookup is necessary.
 *
 * dir->d_inode->i_mutex must be held
 */
static struct dentry *lookup_dcache(struct qstr *name, struct dentry *dir,
                    unsigned int flags, bool *need_lookup)
{
    struct dentry *dentry;
    int error;

    *need_lookup = false;
    dentry = d_lookup(dir, name);
    if (dentry) {
        if (dentry->d_flags & DCACHE_OP_REVALIDATE) {
            error = d_revalidate(dentry, flags);
            if (unlikely(error <= 0)) {
                if (error < 0) {
                    dput(dentry);
                    return ERR_PTR(error);
                } else {
                    d_invalidate(dentry);
                    dput(dentry);
                    dentry = NULL;
                }
            }
        }
    }

    if (!dentry) {
        dentry = d_alloc(dir, name);
        if (unlikely(!dentry))
            return ERR_PTR(-ENOMEM);

        *need_lookup = true;
    }
    return dentry;
}
```
