Linux Ext2 Filesystem
================================================================================

术语
--------------------------------------------------------------------------------

在着手研究 ext2 文件系统之前,让我们先了解文件系统中之专有名词的关联。

* Block(区块):

文件在磁盘中被储存在整数固定大小的区块中, 那区块的大小通帯是2的次方。
在预设中, ext2文件系统的区块大小是4K。研究表示, 4K 字节对于一磁盘区块而言是最理想的
大小,假如一个文件的大小无法达成 4K 字节的倍数时, 那最后的磁盘区块部分就会被浪费。
在最坏的例子中几乎在完整的区块中就有一字节被浪费掉。对于这情况有一点技巧,假如我们
选择了一个较大的区块,则对于小的文件而言会有一些磁盘空间被浪费掉。 另外一方面,假如我们
使用一个非常小的区块,则磁盘区块数量会成挃数的增加, 因此对于档案而言需有更多的搜寻时间。
所以,选择区块大小必须三思而后行。
当一个文件被加载到内存时,那磁盘区块会被放在主存储器中的缓冲存储区,假如它们已经变更了,
 区块在缓冲区中会被标记为’Dirty’, 其表示的是这些区块必须先写到磁盘中来维持磁盘上的区块
及在主存储器中的区块之一致性.

* Superblock:

superblock 是在每个文件系统开始的位置, 其储存信息是文件系统的大小,空的和填满的区块,
它们各自的总数和其他诸如此类的数据。 要从一个文件系统中存取任何档案皆须经过文件系统中
的superblock。如果superblock损坏了, 它可能无法从磁盘中去取得数据。

* Inode:

对于文件系统而言一个inode是在inode表格中的一个项目。 Inode 包含了所有文件
有关的信息例如名称、大小、连接的数量、数据建立之日期, 修改及存取的时间。
它也包含了磁盘区块的文件指针(pointer)。pointer 是用来记录文件被储存在何处

Ext2 磁盘数据结构
--------------------------------------------------------------------------------

任何Ext2分区中的第一个块从不受Ext2文件系统的管理,因为这一块是为分区的引导扇区所保留的.
Ext2分区的其余部分分成块组(block group),每个块组的分布图如下所示:

```
|------------------------------------------------------------------------------|
| 引导块 | 块组0 | ...... | 块组n
|------------------------------------------------------------------------------|
```

如图所示,一些数据结构正好可以放在一个块中,而另一些可能需要更多的块.
在Ext2文件系统中的所有块组大小相同并顺序存放,因此,内核可以从块组的
整数索引很容易地得到磁盘中一个块组的位置.

块组0的分布图如下所示:

```
|-------------------------------------------------------------------------------------|
| 超级块(1) | 组描述符(n) | 数据块位图(1) | 索引节点位图(1) | 索引节点表(n) | 数据块(n)
|-------------------------------------------------------------------------------------|
```

由于内核尽可能地把属于一个文件的数据块存放在同一个块组中,所以块组减少了文件的碎片.
块组中的每个块包含下列信息之一:

* 文件系统的超级块的一个拷贝
* 一组块组描述符的拷贝
* 一个数据块位图
* 一个索引节点位图
* 一个索引节点表
* 属于文件的一大块数据,即数据块.

**注意**: 通常,超级块与组描述副被复制到每个块组中,只有块组0所包含的超级块和组描述符才由内核使用,
而其余的超级块和组描述符保持不变; 事实上,内核甚至不考虑它们.

### 超级块

Ext2在磁盘上的超级块存放在一个ext2_super_block结构中:

#### ext2_super_block

path: fs/ext2/ext2.h
```
/*
 * Structure of the super block
 */
struct ext2_super_block {
    __le32    s_inodes_count;        /* Inodes count */
    __le32    s_blocks_count;        /* Blocks count */
    __le32    s_r_blocks_count;    /* Reserved blocks count */
    __le32    s_free_blocks_count;    /* Free blocks count */
    __le32    s_free_inodes_count;    /* Free inodes count */
    __le32    s_first_data_block;    /* First Data Block */
    __le32    s_log_block_size;    /* Block size */
    __le32    s_log_frag_size;    /* Fragment size */
    __le32    s_blocks_per_group;    /* # Blocks per group */
    __le32    s_frags_per_group;    /* # Fragments per group */
    __le32    s_inodes_per_group;    /* # Inodes per group */
    __le32    s_mtime;        /* Mount time */
    __le32    s_wtime;        /* Write time */
    __le16    s_mnt_count;        /* Mount count */
    __le16    s_max_mnt_count;    /* Maximal mount count */
    __le16    s_magic;        /* Magic signature */
    __le16    s_state;        /* File system state */
    __le16    s_errors;        /* Behaviour when detecting errors */
    __le16    s_minor_rev_level;     /* minor revision level */
    __le32    s_lastcheck;        /* time of last check */
    __le32    s_checkinterval;    /* max. time between checks */
    __le32    s_creator_os;        /* OS */
    __le32    s_rev_level;        /* Revision level */
    __le16    s_def_resuid;        /* Default uid for reserved blocks */
    __le16    s_def_resgid;        /* Default gid for reserved blocks */
    /*
     * These fields are for EXT2_DYNAMIC_REV superblocks only.
     *
     * Note: the difference between the compatible feature set and
     * the incompatible feature set is that if there is a bit set
     * in the incompatible feature set that the kernel doesn't
     * know about, it should refuse to mount the filesystem.
     *
     * e2fsck's requirements are more strict; if it doesn't know
     * about a feature in either the compatible or incompatible
     * feature set, it must abort and not try to meddle with
     * things it doesn't understand...
     */
    __le32    s_first_ino;         /* First non-reserved inode */
    __le16   s_inode_size;         /* size of inode structure */
    __le16    s_block_group_nr;     /* block group # of this superblock */
    __le32    s_feature_compat;     /* compatible feature set */
    __le32    s_feature_incompat;     /* incompatible feature set */
    __le32    s_feature_ro_compat;     /* readonly-compatible feature set */
    __u8    s_uuid[16];        /* 128-bit uuid for volume */
    char    s_volume_name[16];     /* volume name */
    char    s_last_mounted[64];     /* directory where last mounted */
    __le32    s_algorithm_usage_bitmap; /* For compression */
    /*
     * Performance hints.  Directory preallocation should only
     * happen if the EXT2_COMPAT_PREALLOC flag is on.
     */
    __u8    s_prealloc_blocks;    /* Nr of blocks to try to preallocate*/
    __u8    s_prealloc_dir_blocks;    /* Nr to preallocate for dirs */
    __u16    s_padding1;
    /*
     * Journaling support valid if EXT3_FEATURE_COMPAT_HAS_JOURNAL set.
     */
    __u8    s_journal_uuid[16];    /* uuid of journal superblock */
    __u32    s_journal_inum;        /* inode number of journal file */
    __u32    s_journal_dev;        /* device number of journal file */
    __u32    s_last_orphan;        /* start of list of inodes to delete */
    __u32    s_hash_seed[4];        /* HTREE hash seed */
    __u8    s_def_hash_version;    /* Default hash version to use */
    __u8    s_reserved_char_pad;
    __u16    s_reserved_word_pad;
    __le32    s_default_mount_opts;
     __le32    s_first_meta_bg;     /* First metablock block group */
    __u32    s_reserved[190];    /* Padding to the end of the block */
};
```

### 组描述符

每个块组都有自己的组描述符,它是一个ext2_group_desc结构:

#### ext2_group_desc

path: fs/ext2/ext2.h
```
/*
 * Structure of a blocks group descriptor
 */
struct ext2_group_desc
{
    __le32    bg_block_bitmap;        /* Blocks bitmap block */
    __le32    bg_inode_bitmap;        /* Inodes bitmap block */
    __le32    bg_inode_table;        /* Inodes table block */
    __le16    bg_free_blocks_count;    /* Free blocks count */
    __le16    bg_free_inodes_count;    /* Free inodes count */
    __le16    bg_used_dirs_count;    /* Directories count */
    __le16    bg_pad;
    __le32    bg_reserved[3];
};
```

### 索引节点

索引节点表由一连串连续的块组成,其中每一块包含索引节点的一个预定义号.索引节点表第一个块的块号存放
在组描述符的bg_inode_table中.
所有索引节点的大小相同,即128字节.一个1024字节的块可以包含8个索引节点,一个4096字节的块可以包含32个索引节点.
为了计算出索引节点表占用了多少块,用一个组中的索引节点总数(存放在超级块的s_inodes_per_group中)除以每块中的
索引节点数.
每个Ext2索引节点为ext2_inode结构:

#### ext2_inode

path: fs/ext2/ext2.h
```
/*
 * Structure of an inode on the disk
 */
struct ext2_inode {
    __le16    i_mode;        /* File mode */
    __le16    i_uid;        /* Low 16 bits of Owner Uid */
    __le32    i_size;        /* Size in bytes */
    __le32    i_atime;    /* Access time */
    __le32    i_ctime;    /* Creation time */
    __le32    i_mtime;    /* Modification time */
    __le32    i_dtime;    /* Deletion Time */
    __le16    i_gid;        /* Low 16 bits of Group Id */
    __le16    i_links_count;    /* Links count */
    __le32    i_blocks;    /* Blocks count */
    __le32    i_flags;    /* File flags */
    union {
        struct {
            __le32  l_i_reserved1;
        } linux1;
        struct {
            __le32  h_i_translator;
        } hurd1;
        struct {
            __le32  m_i_reserved1;
        } masix1;
    } osd1;                /* OS dependent 1 */
    __le32    i_block[EXT2_N_BLOCKS];/* Pointers to blocks */
    __le32    i_generation;    /* File version (for NFS) */
    __le32    i_file_acl;    /* File ACL */
    __le32    i_dir_acl;    /* Directory ACL */
    __le32    i_faddr;    /* Fragment address */
    union {
        struct {
            __u8    l_i_frag;    /* Fragment number */
            __u8    l_i_fsize;    /* Fragment size */
            __u16    i_pad1;
            __le16    l_i_uid_high;    /* these 2 fields    */
            __le16    l_i_gid_high;    /* were reserved2[0] */
            __u32    l_i_reserved2;
        } linux2;
        struct {
            __u8    h_i_frag;    /* Fragment number */
            __u8    h_i_fsize;    /* Fragment size */
            __le16    h_i_mode_high;
            __le16    h_i_uid_high;
            __le16    h_i_gid_high;
            __le32    h_i_author;
        } hurd2;
        struct {
            __u8    m_i_frag;    /* Fragment number */
            __u8    m_i_fsize;    /* Fragment size */
            __u16    m_pad1;
            __u32    m_i_reserved2[2];
        } masix2;
    } osd2;                /* OS dependent 2 */
};
```

### 索引节点的增强属性

Ext2索引节点的格式对于文件系统涉及这就好像一件紧身衣,索引节点的长度必须是2的幂,以免造成存放索引节点的块
内碎片.实际上,一个Ext2索引节点的128个字符空间中充满了信息,只有少许空间可以增加新的字段.另一方面,将索引节点
的长度增加至256不仅相当浪费,而且使用不同索引节点长度的Ext2文件之间还会造成兼容问题.
引入增强属性就是要克服上面的问题.这些属性存放在索引节点之外的磁盘块中.索引节点的i_file_acl字段指向一个
存放增强属性的块.具有同样增强属性的不同索引节点可以共享同一个块.
每个增强属性有一个名称和值.两者都编码为变长字符数组.并由ext2_xattr_entry描述符来确定.

#### ext2_xattr_entry

path: fs/ext2/xattr.h
```
struct ext2_xattr_entry {
    __u8    e_name_len;    /* length of name */
    __u8    e_name_index;    /* attribute name index */
    __le16    e_value_offs;    /* offset in disk block of value */
    __le32    e_value_block;    /* disk block attribute is stored on (n/i) */
    __le32    e_value_size;    /* size of attribute value */
    __le32    e_hash;        /* hash value of name and value */
    char    e_name[0];    /* attribute name */
};
```

#### 访问控制列表

访问控制列表可以与每个文件关联,有了这种列表,用户可以为它的文件限定可以访问的用户或用户组名称
以及相应的权限. 增强属性主要就是为了支持ACL才引入.

Ext2的内存数据结构
--------------------------------------------------------------------------------

为了提高效率,当安装Ext2文件系统时,存放在Ext2分区的磁盘数据结构中大部分信息被拷贝到RAM中,从而使内核避免后来的很多读操作.

Ext2数据结构的VFS映像:
```
类型                   磁盘数据结构              内存数据结构            缓存模式
----------------------------------------------------------------------------------
超级块               ext2_super_block            ext2_sb_info            总是缓存
组描述符             ext2_group_desc             ext2_group_desc         总是缓存
块位图               块中的位数组                缓冲区中的位数组         动态
索引节点位图         块中的位数组                缓冲区中的位数组         动态
索引节点             ext2_inode                  ext2_inode_info          动态
数据块               字节数组                     VFS缓冲区               动态
空闲索引节点         ext2_inode                   无                      从不
空闲块               字节数组                     无                      从不
```

### 超级块

VFS超级块的s_fs_info字段指向了一个包含文件系统信息的数据结构.对于Ext2,该字段指向了
ext2_sb_info类型的结构:

#### ext2_sb_info

path: fs/ext2/ext2.h
```
/*
 * second extended-fs super-block data in memory
 */
struct ext2_sb_info {
    unsigned long s_frag_size;    /* Size of a fragment in bytes */
    unsigned long s_frags_per_block;/* Number of fragments per block */
    unsigned long s_inodes_per_block;/* Number of inodes per block */
    unsigned long s_frags_per_group;/* Number of fragments in a group */
    unsigned long s_blocks_per_group;/* Number of blocks in a group */
    unsigned long s_inodes_per_group;/* Number of inodes in a group */
    unsigned long s_itb_per_group;    /* Number of inode table blocks per group */
    unsigned long s_gdb_count;    /* Number of group descriptor blocks */
    unsigned long s_desc_per_block;    /* Number of group descriptors per block */
    unsigned long s_groups_count;    /* Number of groups in the fs */
    unsigned long s_overhead_last;  /* Last calculated overhead */
    unsigned long s_blocks_last;    /* Last seen block count */
    struct buffer_head * s_sbh;    /* Buffer containing the super block */
    struct ext2_super_block * s_es;    /* Pointer to the super block in the buffer */
    struct buffer_head ** s_group_desc;
    unsigned long  s_mount_opt;
    unsigned long s_sb_block;
    kuid_t s_resuid;
    kgid_t s_resgid;
    unsigned short s_mount_state;
    unsigned short s_pad;
    int s_addr_per_block_bits;
    int s_desc_per_block_bits;
    int s_inode_size;
    int s_first_ino;
    spinlock_t s_next_gen_lock;
    u32 s_next_generation;
    unsigned long s_dir_count;
    u8 *s_debts;
    struct percpu_counter s_freeblocks_counter;
    struct percpu_counter s_freeinodes_counter;
    struct percpu_counter s_dirs_counter;
    struct blockgroup_lock *s_blockgroup_lock;
    /* root of the per fs reservation window tree */
    spinlock_t s_rsv_window_lock;
    struct rb_root s_rsv_window_root;
    struct ext2_reserve_window_node s_rsv_window_head;
    /*
     * s_lock protects against concurrent modifications of s_mount_state,
     * s_blocks_last, s_overhead_last and the content of superblock's
     * buffer pointed to by sbi->s_es.
     *
     * Note: It is used in ext2_show_options() to provide a consistent view
     * of the mount options.
     */
    spinlock_t s_lock;
};
```

#### Ext2超级块和组描述符有关的缓冲区与缓冲区首部和ext2_sb_info数据结构之间的关系:

UnderstandingLinuxKernel_3rd.pdf (Page 758)

### 索引节点

在打开文件时,要执行路径名查找.对于不在目录项高速缓存内的路径名元素,会创建一个新的页目录项对象
和索引节点.当VFS访问一个Ext2磁盘索引节点时,它会创建一个ext2_inode_info类型的索引节点描述符.

#### ext2_inode_info

path: fs/ext2/ext2.h
```
/*
 * second extended file system inode data in memory
 */
struct ext2_inode_info {
    __le32    i_data[15];
    __u32    i_flags;
    __u32    i_faddr;
    __u8    i_frag_no;
    __u8    i_frag_size;
    __u16    i_state;
    __u32    i_file_acl;
    __u32    i_dir_acl;
    __u32    i_dtime;

    /*
     * i_block_group is the number of the block group which contains
     * this file's inode.  Constant across the lifetime of the inode,
     * it is used for making block allocation decisions - we try to
     * place a file's data blocks near its inode block, and new inodes
     * near to their parent directory's inode.
     */
    __u32    i_block_group;

    /* block reservation info */
    struct ext2_block_alloc_info *i_block_alloc_info;

    __u32    i_dir_start_lookup;
#ifdef CONFIG_EXT2_FS_XATTR
    /*
     * Extended attributes can be read independently of the main file
     * data. Taking i_mutex even when reading would cause contention
     * between readers of EAs and writers of regular file data, so
     * instead we synchronize on xattr_sem when reading or changing
     * EAs.
     */
    struct rw_semaphore xattr_sem;
#endif
    rwlock_t i_meta_lock;

    /*
     * truncate_mutex is for serialising ext2_truncate() against
     * ext2_getblock().  It also protects the internals of the inode's
     * reservation data structures: ext2_reserve_window and
     * ext2_reserve_window_node.
     */
    struct mutex truncate_mutex;
    struct inode    vfs_inode;
    struct list_head i_orphan;    /* unlinked but open inodes */
};
```
