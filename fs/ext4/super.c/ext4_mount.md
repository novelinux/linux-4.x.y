ext4_mount
========================================

path: fs/ext4/super.c
```
static struct dentry *ext4_mount(struct file_system_type *fs_type, int flags,
               const char *dev_name, void *data)
{
    return mount_bdev(fs_type, flags, dev_name, data, ext4_fill_super);
}
```

ext4_fill_super
----------------------------------------

https://github.com/novelinux/linux-4.x.y/blob/master/fs/ext4/super.c/ext4_fill_super.md

mount_bdev
----------------------------------------

https://github.com/novelinux/linux-4.x.y/blob/master/fs/super.c/ext4_bdev.md
