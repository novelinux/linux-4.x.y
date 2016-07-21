kern_path
========================================

path: fs/namei.c
```
int kern_path(const char *name, unsigned int flags, struct path *path)
{
    return filename_lookup(AT_FDCWD, getname_kernel(name),
                   flags, path, NULL);
}
EXPORT_SYMBOL(kern_path);
```

filename_lookup
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/fs/namei.c/filename_lookup.md
