do_filp_open
========================================

Arguments
----------------------------------------

path: fs/namei.c
```
struct file *do_filp_open(int dfd, struct filename *pathname,
        const struct open_flags *op)
{
    struct nameidata nd;
    int flags = op->lookup_flags;
    struct file *filp;
```

set_nameidata
----------------------------------------

```
    set_nameidata(&nd, dfd, pathname);
```

https://github.com/novelinux/linux-4.x.y/tree/master/fs/namei.c/set_nameidata.md

path_openat
----------------------------------------

```
    filp = path_openat(&nd, op, flags | LOOKUP_RCU);
    if (unlikely(filp == ERR_PTR(-ECHILD)))
        filp = path_openat(&nd, op, flags);
    if (unlikely(filp == ERR_PTR(-ESTALE)))
        filp = path_openat(&nd, op, flags | LOOKUP_REVAL);
```

https://github.com/novelinux/linux-4.x.y/tree/master/fs/namei.c/path_openat.md

restore_nameidata
----------------------------------------

```
    restore_nameidata();
    return filp;
}
```

https://github.com/novelinux/linux-4.x.y/tree/master/fs/namei.c/restore_nameidata.md
