__get_fs_type
========================================

path: fs/filesystems.c
```
static struct file_system_type *__get_fs_type(const char *name, int len)
{
    struct file_system_type *fs;

    read_lock(&file_systems_lock);
    fs = *(find_filesystem(name, len));
    if (fs && !try_module_get(fs->owner))
        fs = NULL;
    read_unlock(&file_systems_lock);
    return fs;
}
```

find_filesystem
----------------------------------------

https://github.com/novelinux/linux-4.x.y/blob/master/fs/filesystems.c/find_filesystem.md
