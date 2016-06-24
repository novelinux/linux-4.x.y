ramfs_fs_type
========================================

path: fs/ramfs/inode.c
```
static struct file_system_type ramfs_fs_type = {
    .name        = "ramfs",
    .mount        = ramfs_mount,
    .kill_sb    = ramfs_kill_sb,
    .fs_flags    = FS_USERNS_MOUNT,
};
```