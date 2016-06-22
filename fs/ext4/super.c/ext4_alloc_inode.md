ext4_alloc_inode
========================================

path: fs/ext4/super.c
```
/*
 * Called inside transaction, so use GFP_NOFS
 */
static struct inode *ext4_alloc_inode(struct super_block *sb)
{
    struct ext4_inode_info *ei;

    ei = kmem_cache_alloc(ext4_inode_cachep, GFP_NOFS);
    if (!ei)
        return NULL;

    ei->vfs_inode.i_version = 1;
    spin_lock_init(&ei->i_raw_lock);
    INIT_LIST_HEAD(&ei->i_prealloc_list);
    spin_lock_init(&ei->i_prealloc_lock);
    ext4_es_init_tree(&ei->i_es_tree);
    rwlock_init(&ei->i_es_lock);
    INIT_LIST_HEAD(&ei->i_es_list);
    ei->i_es_all_nr = 0;
    ei->i_es_shk_nr = 0;
    ei->i_es_shrink_lblk = 0;
    ei->i_reserved_data_blocks = 0;
    ei->i_reserved_meta_blocks = 0;
    ei->i_allocated_meta_blocks = 0;
    ei->i_da_metadata_calc_len = 0;
    ei->i_da_metadata_calc_last_lblock = 0;
    spin_lock_init(&(ei->i_block_reservation_lock));
#ifdef CONFIG_QUOTA
    ei->i_reserved_quota = 0;
    memset(&ei->i_dquot, 0, sizeof(ei->i_dquot));
#endif
    ei->jinode = NULL;
    INIT_LIST_HEAD(&ei->i_rsv_conversion_list);
    spin_lock_init(&ei->i_completed_io_lock);
    ei->i_sync_tid = 0;
    ei->i_datasync_tid = 0;
    atomic_set(&ei->i_ioend_count, 0);
    atomic_set(&ei->i_unwritten, 0);
    INIT_WORK(&ei->i_rsv_conversion_work, ext4_end_io_rsv_work);
#ifdef CONFIG_EXT4_FS_ENCRYPTION
    ei->i_crypt_info = NULL;
#endif
    return &ei->vfs_inode;
}
```

ext4_es_init_tree
----------------------------------------

https://github.com/novelinux/linux-4.x.y/blob/master/fs/ext4/extents_status.c/ext4_es_init_tree.md
