ext4_fs_type
========================================

path: fs/ext4/super.c
```
static struct file_system_type ext4_fs_type = {
    .owner        = THIS_MODULE,
    .name        = "ext4",
```

mount
----------------------------------------

```
    .mount        = ext4_mount,
```

https://github.com/novelinux/linux-4.x.y/blob/master/fs/ext4/super.c/ext4_mount.md

kill_sb
----------------------------------------

```
    .kill_sb    = kill_block_super,
    .fs_flags    = FS_REQUIRES_DEV,
};
MODULE_ALIAS_FS("ext4");
```