rootfs_fs_type
========================================

path: init/do_mounts.c
```
static struct file_system_type rootfs_fs_type = {
    .name       = "rootfs",
    .mount      = rootfs_mount,
    .kill_sb    = kill_litter_super,
};
```
