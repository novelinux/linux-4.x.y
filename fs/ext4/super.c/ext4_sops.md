ext4_sops
========================================

alloc_inode
----------------------------------------

path: fs/ext4/super.c
```
static const struct super_operations ext4_sops = {
    .alloc_inode    = ext4_alloc_inode,
```

https://github.com/novelinux/linux-4.x.y/blob/master/fs/ext4/super.c/ext4_alloc_inode.md

destroy_inode
----------------------------------------

```
    .destroy_inode    = ext4_destroy_inode,
    .write_inode    = ext4_write_inode,
    .dirty_inode    = ext4_dirty_inode,
    .drop_inode    = ext4_drop_inode,
    .evict_inode    = ext4_evict_inode,
    .put_super    = ext4_put_super,
    .sync_fs    = ext4_sync_fs,
    .freeze_fs    = ext4_freeze,
    .unfreeze_fs    = ext4_unfreeze,
    .statfs        = ext4_statfs,
    .remount_fs    = ext4_remount,
    .show_options    = ext4_show_options,
#ifdef CONFIG_QUOTA
    .quota_read    = ext4_quota_read,
    .quota_write    = ext4_quota_write,
    .get_dquots    = ext4_get_dquots,
#endif
    .bdev_try_to_free_page = bdev_try_to_free_page,
};
```