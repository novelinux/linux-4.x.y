init_ramfs_fs
========================================

path: fs/ramfs/inode.c
```
int __init init_ramfs_fs(void)
{
    static unsigned long once;

    if (test_and_set_bit(0, &once))
        return 0;
    return register_filesystem(&ramfs_fs_type);
}
fs_initcall(init_ramfs_fs);
```

ramfs_fs_type
----------------------------------------

https://github.com/novelinux/linux-4.x.y/blob/master/fs/ramfs/ramfs_fs_type.md
