rootfs_mount
========================================

Arguments
----------------------------------------

path: init/do_mounts.c
```
static struct dentry *rootfs_mount(struct file_system_type *fs_type,
    int flags, const char *dev_name, void *data)
{
    static unsigned long once;
```

ramfs_fill_super
----------------------------------------

```
    void *fill = ramfs_fill_super;
```

https://github.com/novelinux/linux-4.x.y/blob/master/fs/ramfs/inode.c/ramfs_fill_super.md

shmem_fill_super
----------------------------------------

```
    if (test_and_set_bit(0, &once))
        return ERR_PTR(-ENODEV);

    if (IS_ENABLED(CONFIG_TMPFS) && is_tmpfs)
        fill = shmem_fill_super;
```

mount_nodev
----------------------------------------

接下来调用上述设置的填充超级块信息的函数来完成具体的操作.
最终返回对应分区文件系统的根目录dentry信息.

```
    return mount_nodev(fs_type, flags, data, fill);
}
```

https://github.com/novelinux/linux-4.x.y/blob/master/fs/super.c/mount_nodev.md
