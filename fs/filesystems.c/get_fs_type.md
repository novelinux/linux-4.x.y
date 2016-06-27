get_fs_type
========================================

Arguments
----------------------------------------

path: fs/filesystems.c
```
struct file_system_type *get_fs_type(const char *name)
{
    struct file_system_type *fs;
    const char *dot = strchr(name, '.');
    int len = dot ? dot - name : strlen(name);
```

__get_fs_type
----------------------------------------

```
    fs = __get_fs_type(name, len);
```

https://github.com/novelinux/linux-4.x.y/blob/master/fs/filesystems.c/__get_fs_type.md

request_module
----------------------------------------

```
    if (!fs && (request_module("fs-%.*s", len, name) == 0))
        fs = __get_fs_type(name, len);

    if (dot && fs && !(fs->fs_flags & FS_HAS_SUBTYPE)) {
        put_filesystem(fs);
        fs = NULL;
    }
    return fs;
}

EXPORT_SYMBOL(get_fs_type);
```
