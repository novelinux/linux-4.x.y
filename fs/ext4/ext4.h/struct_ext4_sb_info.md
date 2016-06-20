struct ext4_sb_info
========================================

path: fs/ext4/ext4.h
```
/* Number of quota types we support */
#define EXT4_MAXQUOTAS 2

/*
 * fourth extended-fs super-block data in memory
 */
struct ext4_sb_info {
    unsigned long s_desc_size;    /* Size of a group descriptor in bytes */
    unsigned long s_inodes_per_block;/* Number of inodes per block */
    unsigned long s_blocks_per_group;/* Number of blocks in a group */
    unsigned long s_clusters_per_group; /* Number of clusters in a group */
    unsigned long s_inodes_per_group;/* Number of inodes in a group */
    unsigned long s_itb_per_group;    /* Number of inode table blocks per group */
    unsigned long s_gdb_count;    /* Number of group descriptor blocks */
    unsigned long s_desc_per_block;    /* Number of group descriptors per block */
    ext4_group_t s_groups_count;    /* Number of groups in the fs */
    ext4_group_t s_blockfile_groups;/* Groups acceptable for non-extent files */
    unsigned long s_overhead;  /* # of fs overhead clusters */
    unsigned int s_cluster_ratio;    /* Number of blocks per cluster */
    unsigned int s_cluster_bits;    /* log2 of s_cluster_ratio */
    loff_t s_bitmap_maxbytes;    /* max bytes for bitmap files */
    struct buffer_head * s_sbh;    /* Buffer containing the super block */
    struct ext4_super_block *s_es;    /* Pointer to the super block in the buffer */
    struct buffer_head **s_group_desc;
    unsigned int s_mount_opt;
    unsigned int s_mount_opt2;
    unsigned int s_mount_flags;
    unsigned int s_def_mount_opt;
    ext4_fsblk_t s_sb_block;
    atomic64_t s_resv_clusters;
    kuid_t s_resuid;
    kgid_t s_resgid;
    unsigned short s_mount_state;
    unsigned short s_pad;
    int s_addr_per_block_bits;
    int s_desc_per_block_bits;
    int s_inode_size;
    int s_first_ino;
    unsigned int s_inode_readahead_blks;
    unsigned int s_inode_goal;
    spinlock_t s_next_gen_lock;
    u32 s_next_generation;
    u32 s_hash_seed[4];
    int s_def_hash_version;
    int s_hash_unsigned;    /* 3 if hash should be signed, 0 if not */
    struct percpu_counter s_freeclusters_counter;
    struct percpu_counter s_freeinodes_counter;
    struct percpu_counter s_dirs_counter;
    struct percpu_counter s_dirtyclusters_counter;
    struct blockgroup_lock *s_blockgroup_lock;
    struct proc_dir_entry *s_proc;
    struct kobject s_kobj;
    struct completion s_kobj_unregister;
    struct super_block *s_sb;

    /* Journaling */
    struct journal_s *s_journal;
    struct list_head s_orphan;
    struct mutex s_orphan_lock;
    unsigned long s_resize_flags;        /* Flags indicating if there
                           is a resizer */
    unsigned long s_commit_interval;
    u32 s_max_batch_time;
    u32 s_min_batch_time;
    struct block_device *journal_bdev;
#ifdef CONFIG_QUOTA
    char *s_qf_names[EXT4_MAXQUOTAS];    /* Names of quota files with journalled quota */
    int s_jquota_fmt;            /* Format of quota to use */
#endif
    unsigned int s_want_extra_isize; /* New inodes should reserve # bytes */
    struct rb_root system_blks;

#ifdef EXTENTS_STATS
    /* ext4 extents stats */
    unsigned long s_ext_min;
    unsigned long s_ext_max;
    unsigned long s_depth_max;
    spinlock_t s_ext_stats_lock;
    unsigned long s_ext_blocks;
    unsigned long s_ext_extents;
#endif

    /* for buddy allocator */
    struct ext4_group_info ***s_group_info;
    struct inode *s_buddy_cache;
    spinlock_t s_md_lock;
    unsigned short *s_mb_offsets;
    unsigned int *s_mb_maxs;
    unsigned int s_group_info_size;

    /* tunables */
    unsigned long s_stripe;
    unsigned int s_mb_stream_request;
    unsigned int s_mb_max_to_scan;
    unsigned int s_mb_min_to_scan;
    unsigned int s_mb_stats;
    unsigned int s_mb_order2_reqs;
    unsigned int s_mb_group_prealloc;
    unsigned int s_max_dir_size_kb;
    /* where last allocation was done - for stream allocation */
    unsigned long s_mb_last_group;
    unsigned long s_mb_last_start;

    /* stats for buddy allocator */
    atomic_t s_bal_reqs;    /* number of reqs with len > 1 */
    atomic_t s_bal_success;    /* we found long enough chunks */
    atomic_t s_bal_allocated;    /* in blocks */
    atomic_t s_bal_ex_scanned;    /* total extents scanned */
    atomic_t s_bal_goals;    /* goal hits */
    atomic_t s_bal_breaks;    /* too long searches */
    atomic_t s_bal_2orders;    /* 2^order hits */
    spinlock_t s_bal_lock;
    unsigned long s_mb_buddies_generated;
    unsigned long long s_mb_generation_time;
    atomic_t s_mb_lost_chunks;
    atomic_t s_mb_preallocated;
    atomic_t s_mb_discarded;
    atomic_t s_lock_busy;

    /* locality groups */
    struct ext4_locality_group __percpu *s_locality_groups;

    /* for write statistics */
    unsigned long s_sectors_written_start;
    u64 s_kbytes_written;

    /* the size of zero-out chunk */
    unsigned int s_extent_max_zeroout_kb;

    unsigned int s_log_groups_per_flex;
    struct flex_groups *s_flex_groups;
    ext4_group_t s_flex_groups_allocated;

    /* workqueue for reserved extent conversions (buffered io) */
    struct workqueue_struct *rsv_conversion_wq;

    /* timer for periodic error stats printing */
    struct timer_list s_err_report;

    /* Lazy inode table initialization info */
    struct ext4_li_request *s_li_request;
    /* Wait multiplier for lazy initialization thread */
    unsigned int s_li_wait_mult;

    /* Kernel thread for multiple mount protection */
    struct task_struct *s_mmp_tsk;

    /* record the last minlen when FITRIM is called. */
    atomic_t s_last_trim_minblks;

    /* Reference to checksum algorithm driver via cryptoapi */
    struct crypto_shash *s_chksum_driver;

    /* Precomputed FS UUID checksum for seeding other checksums */
    __u32 s_csum_seed;

    /* Reclaim extents from extent status tree */
    struct shrinker s_es_shrinker;
    struct list_head s_es_list;    /* List of inodes with reclaimable extents */
    long s_es_nr_inode;
    struct ext4_es_stats s_es_stats;
    struct mb_cache *s_mb_cache;
    spinlock_t s_es_lock ____cacheline_aligned_in_smp;

    /* Ratelimit ext4 messages. */
    struct ratelimit_state s_err_ratelimit_state;
    struct ratelimit_state s_warning_ratelimit_state;
    struct ratelimit_state s_msg_ratelimit_state;
};
```