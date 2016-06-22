struct ext4_inode_info
========================================

path: fs/ext4/ext4.h
```
/*
 * fourth extended file system inode data in memory
 */
struct ext4_inode_info {
    __le32    i_data[15];    /* unconverted */
    __u32    i_dtime;
    ext4_fsblk_t    i_file_acl;

    /*
     * i_block_group is the number of the block group which contains
     * this file's inode.  Constant across the lifetime of the inode,
     * it is ued for making block allocation decisions - we try to
     * place a file's data blocks near its inode block, and new inodes
     * near to their parent directory's inode.
     */
    ext4_group_t    i_block_group;
    ext4_lblk_t    i_dir_start_lookup;
#if (BITS_PER_LONG < 64)
    unsigned long    i_state_flags;        /* Dynamic state flags */
#endif
    unsigned long    i_flags;

    /*
     * Extended attributes can be read independently of the main file
     * data. Taking i_mutex even when reading would cause contention
     * between readers of EAs and writers of regular file data, so
     * instead we synchronize on xattr_sem when reading or changing
     * EAs.
     */
    struct rw_semaphore xattr_sem;

    struct list_head i_orphan;    /* unlinked but open inodes */

    /*
     * i_disksize keeps track of what the inode size is ON DISK, not
     * in memory.  During truncate, i_size is set to the new size by
     * the VFS prior to calling ext4_truncate(), but the filesystem won't
     * set i_disksize to 0 until the truncate is actually under way.
     *
     * The intent is that i_disksize always represents the blocks which
     * are used by this file.  This allows recovery to restart truncate
     * on orphans if we crash during truncate.  We actually write i_disksize
     * into the on-disk inode when writing inodes out, instead of i_size.
     *
     * The only time when i_disksize and i_size may be different is when
     * a truncate is in progress.  The only things which change i_disksize
     * are ext4_get_block (growth) and ext4_truncate (shrinkth).
     */
    loff_t    i_disksize;

    /*
     * i_data_sem is for serialising ext4_truncate() against
     * ext4_getblock().  In the 2.4 ext2 design, great chunks of inode's
     * data tree are chopped off during truncate. We can't do that in
     * ext4 because whenever we perform intermediate commits during
     * truncate, the inode and all the metadata blocks *must* be in a
     * consistent state which allows truncation of the orphans to restart
     * during recovery.  Hence we must fix the get_block-vs-truncate race
     * by other means, so we have i_data_sem.
     */
    struct rw_semaphore i_data_sem;
    struct inode vfs_inode;
    struct jbd2_inode *jinode;

    spinlock_t i_raw_lock;    /* protects updates to the raw inode */

    /*
     * File creation time. Its function is same as that of
     * struct timespec i_{a,c,m}time in the generic inode.
     */
    struct timespec i_crtime;

    /* mballoc */
    struct list_head i_prealloc_list;
    spinlock_t i_prealloc_lock;
```

i_es_tree
----------------------------------------

```
    /* extents status tree */
    struct ext4_es_tree i_es_tree;
```

https://github.com/novelinux/linux-4.x.y/blob/master/fs/ext4/extents_status.h/struct_ext4_es_tree.md

i_es_lock
----------------------------------------

```
    rwlock_t i_es_lock;
    struct list_head i_es_list;
    unsigned int i_es_all_nr;    /* protected by i_es_lock */
    unsigned int i_es_shk_nr;    /* protected by i_es_lock */
    ext4_lblk_t i_es_shrink_lblk;    /* Offset where we start searching for
                       extents to shrink. Protected by
                       i_es_lock  */

    /* ialloc */
    ext4_group_t    i_last_alloc_group;

    /* allocation reservation info for delalloc */
    /* In case of bigalloc, these refer to clusters rather than blocks */
    unsigned int i_reserved_data_blocks;
    unsigned int i_reserved_meta_blocks;
    unsigned int i_allocated_meta_blocks;
    ext4_lblk_t i_da_metadata_calc_last_lblock;
    int i_da_metadata_calc_len;

    /* on-disk additional length */
    __u16 i_extra_isize;

    /* Indicate the inline data space. */
    u16 i_inline_off;
    u16 i_inline_size;

#ifdef CONFIG_QUOTA
    /* quota space reservation, managed internally by quota code */
    qsize_t i_reserved_quota;
#endif

    /* Lock protecting lists below */
    spinlock_t i_completed_io_lock;
    /*
     * Completed IOs that need unwritten extents handling and have
     * transaction reserved
     */
    struct list_head i_rsv_conversion_list;
    /*
     * Completed IOs that need unwritten extents handling and don't have
     * transaction reserved
     */
    atomic_t i_ioend_count;    /* Number of outstanding io_end structs */
    atomic_t i_unwritten; /* Nr. of inflight conversions pending */
    struct work_struct i_rsv_conversion_work;

    spinlock_t i_block_reservation_lock;

    /*
     * Transactions that contain inode's metadata needed to complete
     * fsync and fdatasync, respectively.
     */
    tid_t i_sync_tid;
    tid_t i_datasync_tid;

#ifdef CONFIG_QUOTA
    struct dquot *i_dquot[MAXQUOTAS];
#endif

    /* Precomputed uuid+inum+igen checksum for seeding inode checksums */
    __u32 i_csum_seed;

#ifdef CONFIG_EXT4_FS_ENCRYPTION
    /* Encryption params */
    struct ext4_crypt_info *i_crypt_info;
#endif
};
```
