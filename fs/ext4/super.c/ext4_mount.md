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