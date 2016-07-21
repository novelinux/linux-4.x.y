walk_component
========================================

path: fs/namei.c
```
static int walk_component(struct nameidata *nd, int flags)
{
    struct path path;
    struct inode *inode;
    unsigned seq;
    int err;
    /*
     * "." and ".." are special - ".." especially so because it has
     * to be able to know about the current root directory and
     * parent relationships.
     */
    if (unlikely(nd->last_type != LAST_NORM)) {
        err = handle_dots(nd, nd->last_type);
        if (flags & WALK_PUT)
            put_link(nd);
        return err;
    }
    err = lookup_fast(nd, &path, &inode, &seq);
    if (unlikely(err)) {
        if (err < 0)
            return err;

        err = lookup_slow(nd, &path);
        if (err < 0)
            return err;

        inode = d_backing_inode(path.dentry);
        seq = 0;    /* we are already out of RCU mode */
        err = -ENOENT;
        if (d_is_negative(path.dentry))
            goto out_path_put;
    }

    if (flags & WALK_PUT)
        put_link(nd);
    err = should_follow_link(nd, &path, flags & WALK_GET, inode, seq);
    if (unlikely(err))
        return err;
    path_to_nameidata(&path, nd);
    nd->inode = inode;
    nd->seq = seq;
    return 0;

out_path_put:
    path_to_nameidata(&path, nd);
    return err;
}
```