filename_lookup
========================================

path: fs/namei.c
```
static int filename_lookup(int dfd, struct filename *name, unsigned flags,
               struct path *path, struct path *root)
{
    int retval;
    struct nameidata nd;
    if (IS_ERR(name))
        return PTR_ERR(name);
    if (unlikely(root)) {
        nd.root = *root;
        flags |= LOOKUP_ROOT;
    }
```

set_nameidata
----------------------------------------

```
    set_nameidata(&nd, dfd, name);
```

https://github.com/novelinux/linux-4.x.y/tree/master/fs/namei.c/set_nameidata.md

path_lookupat
----------------------------------------

```
    retval = path_lookupat(&nd, flags | LOOKUP_RCU, path);
    if (unlikely(retval == -ECHILD))
        retval = path_lookupat(&nd, flags, path);
    if (unlikely(retval == -ESTALE))
        retval = path_lookupat(&nd, flags | LOOKUP_REVAL, path);
```

https://github.com/novelinux/linux-4.x.y/tree/master/fs/namei.c/path_lookupat.md

restore_nameidata
----------------------------------------

```
    if (likely(!retval))
        audit_inode(name, path->dentry, flags & LOOKUP_PARENT);
    restore_nameidata();
    putname(name);
    return retval;
}
```