struct super_block
========================================

在装载新的文件系统时，vfsmount并不是唯一需要在内存中创建的结构。装载操作开始于超级块的读取。
get_super函数指针返回一个类型为super_block的对象，用于在内存中表示一个超级块。它是借助于底层
实现产生的。

s_list
----------------------------------------

path: include/linux/fs.h
```
struct super_block {
    struct list_head    s_list;        /* Keep this first */
```

结构的第一个成员s_list是一个链表元素，用于将系统中所有的超级块聚集到一个链表中。该链表的表头是
全局变量super_blocks，定义在fs/super.c中。

s_dev
----------------------------------------

```
    dev_t            s_dev;        /* search index; _not_ kdev_t */
```

s_dev指定了底层文件系统的数据所在的块设备,使用了内核内部的编号.

s_blocksize_bits, s_blocksize
----------------------------------------

```
    unsigned char        s_blocksize_bits;
    unsigned long        s_blocksize;
```

s_blocksize和s_blocksize_bits指定了文件系统的块长度。本质上，这两个变量以不同的方式表示了
相同信息。s_blocksize的单位是字节，而s_blocksize_bits则是对前一个值取以2为底的对数。

s_maxbytes
----------------------------------------

```
    loff_t            s_maxbytes;    /* Max file size */
```

s_maxbytes保存了文件系统可以处理的最大文件长度，因实现而异。

s_type
----------------------------------------

```
    struct file_system_type    *s_type;
```

s_type指向file_system_type实例，其中保存了与文件系统有关的一般类型的信息。

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/fs.h/struct_file_system_type.md

s_op
----------------------------------------

```
    const struct super_operations    *s_op;
```

s_op指向一个包含了函数指针的结构，该结构按熟悉的VFS方式，提供了一个一般性的接口，用于处理超级块
相关操作。操作的实现必须由底层文件系统的代码提供。

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/fs.h/struct_super_operations.md

```
    const struct dquot_operations    *dq_op;
    const struct quotactl_ops    *s_qcop;
    const struct export_operations *s_export_op;
    unsigned long        s_flags;
    unsigned long        s_iflags;    /* internal SB_I_* flags */
    unsigned long        s_magic;
```

s_root
----------------------------------------

```
    struct dentry        *s_root;
```

s_root将超级块与全局根目录的dentry项关联起来。只有通常可见的文件系统的超级块，才指向/（根）目录
的dentry实例。具有特殊功能、不出现在通常的目录层次结构中的文件系统（例如，管道或套接字文件系统），
指向专门的项，不能通过普通的文件命令访问。处理文件系统对象的代码经常需要检查文件系统是否已经装载，
而s_root可用于该目的。如果它为NULL，则该文件系统是一个伪文件系统，只在内核内部可见。否则，该文件
系统在用户空间中是可见的。

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/dcache.h/struct_dentry.md

s_umount
----------------------------------------

```
    struct rw_semaphore    s_umount;
    int            s_count;
    atomic_t        s_active;
#ifdef CONFIG_SECURITY
    void                    *s_security;
#endif
```

s_xattr
----------------------------------------

```
    const struct xattr_handler **s_xattr;
```

xattr是一个指向结构的指针，该结构包含了一些用于处理扩展属性的函数指针。

s_anon
----------------------------------------

```
    struct hlist_bl_head    s_anon;        /* anonymous dentries for (nfs) exporting */
    struct list_head    s_mounts;    /* list of mounts; _not_ for fs use */
```

s_bdev
----------------------------------------

```
    struct block_device    *s_bdev;
```

s_bdev指定了底层文件系统的数据所在的块设备，是一个指向内存中的block_device结构的指针.

s_bdi
----------------------------------------

```
    struct backing_dev_info *s_bdi;
    struct mtd_info        *s_mtd;
```

s_instances
----------------------------------------

```
    struct hlist_node    s_instances;
```

最后，各个超级块都连接到另一个链表中，表示同一类型文件系统的所有超级块实例，这里不考虑底层
的块设备，但链表中的超级块的文件系统类型都是相同的。表头是file_system_type结构的fs_supers成员，
s_instances用作链表元素。

```
    unsigned int        s_quota_types;    /* Bitmask of supported quota types */
    struct quota_info    s_dquot;    /* Diskquota specific options */

    struct sb_writers    s_writers;

    char s_id[32];                /* Informational name */
    u8 s_uuid[16];                /* UUID */
```

s_fs_info
----------------------------------------

```
    void             *s_fs_info;    /* Filesystem private info */
```

s_fs_info是一个指向文件系统实现的私有数据的指针，VFS不操作该数据。

```
    unsigned int        s_max_links;
    fmode_t            s_mode;
```

s_time_gran
----------------------------------------

```
    /* Granularity of c/m/atime in ns.
       Cannot be worse than a second */
    u32           s_time_gran;
```

s_time_gran指定了文件系统支持的各种时间戳的最大可能的粒度。该值对所有时间戳都是相同的，
单位为ns，即1秒的109分之一。

```
    /*
     * The next field is for VFS *only*. No filesystems have any business
     * even looking at it. You had been warned.
     */
    struct mutex s_vfs_rename_mutex;    /* Kludge */

    /*
     * Filesystem subtype.  If non-empty the filesystem type field
     * in /proc/mounts will be "type.subtype"
     */
    char *s_subtype;

    /*
     * Saved mount options for lazy filesystems using
     * generic_show_options()
     */
    char __rcu *s_options;
    const struct dentry_operations *s_d_op; /* default d_op for dentries */

    /*
     * Saved pool identifier for cleancache (-1 means none)
     */
    int cleancache_poolid;

    struct shrinker s_shrink;    /* per-sb shrinker handle */

    /* Number of inodes with nlink == 0 but still referenced */
    atomic_long_t s_remove_count;

    /* Being remounted read-only */
    int s_readonly_remount;

    /* AIO completions deferred from interrupt context */
    struct workqueue_struct *s_dio_done_wq;
    struct hlist_head s_pins;

    /*
     * Keep the lru lists last in the structure so they always sit on their
     * own individual cachelines.
     */
    struct list_lru        s_dentry_lru ____cacheline_aligned_in_smp;
    struct list_lru        s_inode_lru ____cacheline_aligned_in_smp;
    struct rcu_head        rcu;
    struct work_struct    destroy_work;

    struct mutex        s_sync_lock;    /* sync serialisation lock */

    /*
     * Indicates how deep in a filesystem stack this SB is
     */
    int s_stack_depth;

    /* s_inode_list_lock protects s_inodes */
    spinlock_t        s_inode_list_lock ____cacheline_aligned_in_smp;
    struct list_head    s_inodes;    /* all inodes */
};
```