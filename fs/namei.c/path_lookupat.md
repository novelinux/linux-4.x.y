path_lookupat
========================================

Arguments
----------------------------------------

path: fs/namei.c
```
/* Returns 0 and nd will be valid on success; Retuns error, otherwise. */
static int path_lookupat(struct nameidata *nd, unsigned flags, struct path *path)
{
```

path_init
----------------------------------------

```
    const char *s = path_init(nd, flags);
    int err;

    if (IS_ERR(s))
        return PTR_ERR(s);
```

https://github.com/novelinux/linux-4.x.y/blob/master/fs/namei.c/path_init.md

walk
----------------------------------------

```
    while (!(err = link_path_walk(s, nd))
        && ((err = lookup_last(nd)) > 0)) {
        s = trailing_symlink(nd);
        if (IS_ERR(s)) {
            err = PTR_ERR(s);
            break;
        }
    }
    if (!err)
        err = complete_walk(nd);
```

### link_path_walk

https://github.com/novelinux/linux-4.x.y/blob/master/fs/namei.c/link_path_walk.md

### lookup_last

https://github.com/novelinux/linux-4.x.y/blob/master/fs/namei.c/lookup_last.md

### trailing_symlink

d_can_lookup
----------------------------------------

```
    if (!err && nd->flags & LOOKUP_DIRECTORY)
        if (!d_can_lookup(nd->path.dentry))
            err = -ENOTDIR;
    if (!err) {
        *path = nd->path;
        nd->path.mnt = NULL;
        nd->path.dentry = NULL;
    }
```

terminate_walk
----------------------------------------

```
    terminate_walk(nd);
    return err;
}
```