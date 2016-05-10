Linux VFS Data Structure
================================================================================

文件系统类型注册
--------------------------------------------------------------------------------

通常,用户在为自己的系统编译内核时可以把Linux配置为能够识别所有需要的文件系统.
但是,文件系统的源代码实际上要么包含在内核的影像中,要么作为一个模块被动态装入.VFS必须对代码目前
已经在内核中的所有文件系统的类型进行跟踪,这就是通过进行文件系统类型注册来实现的.
每个注册的文件系统都用一个类型为file_system_type的对象来表示:

#### file_system_type

path: include/linux/fs.h
```
struct file_system_type {
    const char *name;    /* 文件系统名称 */
    int fs_flags;        /* 文件系统类型标志 */

/* fs_flags存放几个标志 */
#define FS_REQUIRES_DEV      1  /* 这种类型的任何文件系统必须位于物理磁盘设备上 */
#define FS_BINARY_MOUNTDATA  2  /* 文件系统使用二进制安装数据 */
#define FS_HAS_SUBTYPE       4
#define FS_USERNS_MOUNT      8 /* Can be mounted by userns root */
#define FS_USERNS_DEV_MOUNT 16 /* A userns mount does not imply MNT_NODEV */
/* FS will handle d_move() during rename() internally. */
#define FS_RENAME_DOES_D_MOVE 32768

    struct dentry *(*mount) (struct file_system_type *, int,
       const char *, void *);   /* 成员函数负责超级块,根目录和索引节点的创建和初始化工作 */

    void (*kill_sb) (struct super_block *); /* 删除超级块的方法 */

    struct module *owner;  /* 指向实现文件系统的模块的指针 */
    struct file_system_type * next; /* 指向文件系统类型链表中下一个元素的指针 */
    struct hlist_head fs_supers;    /* 具有相同文件系统类型的超级块对象链表的头 */

    struct lock_class_key s_lock_key;
    struct lock_class_key s_umount_key;
    struct lock_class_key s_vfs_rename_key;
    struct lock_class_key s_writers_key[SB_FREEZE_LEVELS];

    struct lock_class_key i_lock_key;
    struct lock_class_key i_mutex_key;
    struct lock_class_key i_mutex_dir_key;
};
```

所有文件系统类型的对象都插入到一个单向链表中.由变量"file_systems"指向链表的第一个元素,
而结构中的"next"字段指向链表的下一个元素."file_systems_lock" 读写自旋锁保护整个链表免受同时访问.
"fs_supers" 字段表示给定类型的已安装文件系统所对应的超级块链表的头.

#### 函数

* register_filesystem: 注册编译时指定的每个文件系统,该函数把相应的file_system_type对象插入到文件系统类型的链表中.
  当实现了文件系统以模块方式装入的时候,也要调用该函数.
* unregister_filesystem: 当实现了文件系统以模块方式装入,当该模块卸载是,注销对应的文件系统
* get_fs_type: 扫描已注册的文件系统链表以查找文件系统类型的name字段,并返回指向相应的file_system_type对象(如果存在)的指针.

文件系统安装
--------------------------------------------------------------------------------

在大多数传统的类Unix内核中,每个文件系统只能安装一次.假定存放在/dev/fd0软盘上的ext2文件系统通过如下命令安装在/flp:

```
$ mount -t ext2 /dev/fd0 /flp
```
在用umount命令卸载该文件系统前,所有其他作用于/dev/fd0的安装命令都会失败.
然而,Linux有所不同: 同一个文件系统被安装多次是可能的. 当然,如果一个文件系统被安装了n次,那么它的根目录就可以通过n个安装点来访问.
尽管同一个文件系统可以通过不同的安装点来访问,但是文件系统的的确确是唯一的.因此,不管一个文件系统被安装了多少次,都仅有一个超级块对象.

安装的文件系统形成一个层次: 一个文件系统的安装点可能成为第二个文件系统的目录,而第二个文件系统又安装在第三个文件系统之上.

把多个文件系统安装堆叠在一个单独的安装点上也是可能的.尽管已经使用先前安装下的文件和目录的进程可以继续使用,但在统一安装点上,
隐藏前一个安装的文件系统.当最顶层的被删除时,下一层的再一次变为可见.

综上, 跟踪已安装的文件系统会变为一场噩梦.对于每个安装操作,内核必须在内存中保存安装点和安装标志,以及要安装文件系统与其它已安装文件系统
的关系.这样的信息保存在已安装文件系统描述符中.每个描述符是一个具有vfsmount类型的数据结构:

#### mount

path: fs/mount.h
```
struct mount {
	struct hlist_node mnt_hash;
	struct mount *mnt_parent;
	struct dentry *mnt_mountpoint;
	struct vfsmount mnt;
	struct rcu_head mnt_rcu;
#ifdef CONFIG_SMP
	struct mnt_pcp __percpu *mnt_pcp;
#else
	int mnt_count;
	int mnt_writers;
#endif
	struct list_head mnt_mounts;	/* list of children, anchored here */
	struct list_head mnt_child;	/* and going through their mnt_child */
	struct list_head mnt_instance;	/* mount instance on sb->s_mounts */
	const char *mnt_devname;	/* Name of device e.g. /dev/dsk/hda1 */
	struct list_head mnt_list;
	struct list_head mnt_expire;	/* link in fs-specific expiry list */
	struct list_head mnt_share;	/* circular list of shared mounts */
	struct list_head mnt_slave_list;/* list of slave mounts */
	struct list_head mnt_slave;	/* slave list entry */
	struct mount *mnt_master;	/* slave is on master->mnt_slave_list */
	struct mnt_namespace *mnt_ns;	/* containing namespace */
	struct mountpoint *mnt_mp;	/* where is it mounted */
#ifdef CONFIG_FSNOTIFY
	struct hlist_head mnt_fsnotify_marks;
	__u32 mnt_fsnotify_mask;
#endif
	int mnt_id;			/* mount identifier */
	int mnt_group_id;		/* peer group identifier */
	int mnt_expiry_mark;		/* true if marked for expiry */
	int mnt_pinned;
	struct path mnt_ex_mountpoint;
};
```

#### vfsmount

path: include/linux/mount.h
```
struct vfsmount {
    /* 指向这个文件系统根目录的dentry */
    struct dentry *mnt_root;    /* root of the mounted tree */
    /* 指向这个文件系统的超级块对象 */
    struct super_block *mnt_sb; /* pointer to superblock */
    /* 标志 */
    int mnt_flags;
};
```
**注意**: 一个文件系统的安装点可能就是同一文件系统的一个目录,例如:

```
$ mount -t ext2 /dev/fd0 /flp
$ touch /flp/foo
$ mkdir /flp/mnt
$ mount -t ext2 /dev/fd0 /flp/mnt
```
现在,软盘文件系统上的空foo文件就可以通过/flp/foo和/flp/mnt/foo来访问

超级块对象
--------------------------------------------------------------------------------

超级块结构表示一个文件系统. 它包含管理文件系统所需的信息, 包括文件系统名称(比如ext2),文件系统的大小和状态,块设备的引用和
元数据信息(比如空闲列表等等).超级块通常存储在存储媒体上, 但是如果超级块不存在, 也可以实时创建它.

#### super_block

path: include/linux/fs.h
```
struct super_block {
    struct list_head s_list;    /* Keep this first */ /* 指向超级块链表的指针 */
    dev_t s_dev;  /* search index; _not_ kdev_t */ /* 设备标识符 */
    unsigned char s_blocksize_bits;  /* 以位为单位的块大小 */
    unsigned long s_blocksize;       /* 以字节为单位的快大小 */
    loff_t s_maxbytes; /* Max file size */ /* 文件的最大长度 */
    struct file_system_type *s_type;       /* 文件系统类型 */

    const struct super_operations *s_op;   /* 操作超级块的方法 */
    const struct dquot_operations *dq_op;  /* 磁盘限额处理方法 */
    const struct quotactl_ops *s_qcop;     /* 磁盘限额管理方法 */
    const struct export_operations *s_export_op; /* 网络文件系统使用的输出操作 */

    unsigned long s_flags;    /* 安装标志 */
    unsigned long s_magic;    /* 文件系统的魔数 */
    struct dentry *s_root;    /* 文件系统根目录的目录项对象 */
    struct rw_semaphore s_umount; /* 卸载所用的信号量 */
    int s_count;          /* 引用计数器 */
    atomic_t s_active;    /* 次级引用计数器 */
#ifdef CONFIG_SECURITY
    void                    *s_security; /* 指向超级块安全数据结构的指针 */
#endif
    const struct xattr_handler **s_xattr; /* 指向超级块扩展属性结构的指针 */

    struct list_head s_inodes; /* all inodes */ /* 所有索引节点的链表 */
    /* 用于处理远程网络文件系统的匿名目录项的链表 */
    struct hlist_bl_head s_anon; /* anonymous dentries for (nfs) exporting */
    struct list_head s_mounts;   /* list of mounts; _not_ for fs use */

    struct block_device *s_bdev; /* 指向块设备驱动程序描述符的指针 */
    struct backing_dev_info *s_bdi;
    struct mtd_info *s_mtd;
    struct hlist_node s_instances; /* 用于给定文件系统类型的超级块对象链表的指针 */
    struct quota_info s_dquot; /* Diskquota specific options */ /* 磁盘限额的描述符 */

    struct sb_writers s_writers;

    char s_id[32]; /* Informational name */ /* 包含超级块的块设备名称 */
    u8 s_uuid[16]; /* UUID */

    void *s_fs_info; /* Filesystem private info */  /* 指向文件系统的私有信息 */
    unsigned int s_max_links;
    fmode_t s_mode;

    /* Granularity of c/m/atime in ns.
       Cannot be worse than a second */
    u32 s_time_gran;

    /*
     * The next field is for VFS *only*. No filesystems have any business
     * even looking at it. You had been warned.
     */
    struct mutex s_vfs_rename_mutex; /* Kludge */

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

     struct shrinker s_shrink; /* per-sb shrinker handle */

     /* Number of inodes with nlink == 0 but still referenced */
     atomic_long_t s_remove_count;

     /* Being remounted read-only */
     int s_readonly_remount;

     /* AIO completions deferred from interrupt context */
     struct workqueue_struct *s_dio_done_wq;

     /*
      * Keep the lru lists last in the structure so they always sit on their
      * own individual cachelines.
      */
     struct list_lru s_dentry_lru ____cacheline_aligned_in_smp;
     struct list_lru s_inode_lru ____cacheline_aligned_in_smp;
     struct rcu_head rcu;
};
```

所有超级块对象都以双向循环链表的形式链接在一起,链表中的第一个元素用"super_blocks"变量来表示.
而超级块对象的"s_list"字段存放指向链表相邻元素的指针. "sb_lock"自旋锁保护链表妙手多处理器系统上的同时访问.
"s_fs_info"字段指向属于具体文件系统的超级块信息; 例如,假如超级块对象指向的是Ext2文件系统,该字段就指向
ext2_sb_info数据结构.为了效率起见,由s_fs_info所指向的数据被复制到内存.任何基于磁盘的文件系统都需要访问
和更改自己的磁盘分配位图,以便分配或释放磁盘块. VFS允许这些文件系统直接对内存超级块的s_fs_info字段进行
操作,而无需访问磁盘.


#### super_operations

与超级块关联的方法就是所谓的超级块操作.这些操作是由数据结构super_operations来描述的.

path: include/linux/fs.h
```
struct super_operations {
    /* 为索引节点对象分配空间,包括文件系统数据所需要的空间 */
    struct inode *(*alloc_inode)(struct super_block *sb);
    /* 撤销索引节点对象,包括具体文件系统的数据 */
    void (*destroy_inode)(struct inode *);

    /* 当索引节点标记为修改(脏)时调用. */
    void (*dirty_inode) (struct inode *, int flags);
    /* 用通过传递参数指定的索引节点对象的内容更新一个文件系统的索引节点.索引节点对象的i_ino字段表示所涉及磁盘上文件系统的索引节点 */
    int (*write_inode) (struct inode *, struct writeback_control *wbc);
    int (*drop_inode) (struct inode *);
    void (*evict_inode) (struct inode *);
    void (*put_super) (struct super_block *);
    int (*sync_fs)(struct super_block *sb, int wait);
    int (*freeze_fs) (struct super_block *);
    int (*unfreeze_fs) (struct super_block *);
    int (*statfs) (struct dentry *, struct kstatfs *);
    int (*remount_fs) (struct super_block *, int *, char *);
    void (*umount_begin) (struct super_block *);

    int (*show_options)(struct seq_file *, struct dentry *);
    int (*show_devname)(struct seq_file *, struct dentry *);
    int (*show_path)(struct seq_file *, struct dentry *);
    int (*show_stats)(struct seq_file *, struct dentry *);
#ifdef CONFIG_QUOTA
    ssize_t (*quota_read)(struct super_block *, int, char *, size_t, loff_t);
    ssize_t (*quota_write)(struct super_block *, int, const char *, size_t, loff_t);
#endif
    int (*bdev_try_to_free_page)(struct super_block*, struct page*, gfp_t);
    long (*nr_cached_objects)(struct super_block *, int);
    long (*free_cached_objects)(struct super_block *, long, int);
};
```

索引节点对象
--------------------------------------------------------------------------------

文件系统处理文件所需要的所有信息都存放在一个名为索引节点的数据结构中.文件名可以随时改正
但是索引节点对文件是唯一的,并且随文件的存在而存在.内存中的索引节点对象由一个inode数据结构组成.

#### inode

path: include/linux/fs.h
```
/*
 * Keep mostly read-only and often accessed (especially for
 * the RCU path lookup and 'stat' data) fields at the beginning
 * of the 'struct inode'
 */
struct inode {
   umode_t                      i_mode;
   unsigned short		i_opflags;
   kuid_t			i_uid;
   kgid_t			i_gid;
   unsigned int		i_flags;

#ifdef CONFIG_FS_POSIX_ACL
	struct posix_acl	*i_acl;
	struct posix_acl	*i_default_acl;
#endif

	const struct inode_operations	*i_op;
	struct super_block	*i_sb;
	struct address_space	*i_mapping;

#ifdef CONFIG_SECURITY
	void			*i_security;
#endif

	/* Stat data, not accessed from path walking */
	unsigned long		i_ino;
	/*
	 * Filesystems may only read i_nlink directly.  They shall use the
	 * following functions for modification:
	 *
	 *    (set|clear|inc|drop)_nlink
	 *    inode_(inc|dec)_link_count
	 */
	union {
		const unsigned int i_nlink;
		unsigned int __i_nlink;
	};
	dev_t			i_rdev;
	loff_t			i_size;
	struct timespec		i_atime;
	struct timespec		i_mtime;
	struct timespec		i_ctime;
	spinlock_t		i_lock;	/* i_blocks, i_bytes, maybe i_size */
	unsigned short          i_bytes;
	unsigned int		i_blkbits;
	blkcnt_t		i_blocks;

#ifdef __NEED_I_SIZE_ORDERED
	seqcount_t		i_size_seqcount;
#endif

	/* Misc */
	unsigned long		i_state;
	struct mutex		i_mutex;

	unsigned long		dirtied_when;	/* jiffies of first dirtying */

	struct hlist_node	i_hash;
	struct list_head	i_wb_list;	/* backing dev IO list */
	struct list_head	i_lru;		/* inode LRU list */
	struct list_head	i_sb_list;
	union {
		struct hlist_head	i_dentry;
		struct rcu_head		i_rcu;
	};
	u64			i_version;
	atomic_t		i_count;
	atomic_t		i_dio_count;
	atomic_t		i_writecount;
	const struct file_operations	*i_fop;	/* former ->i_op->default_file_ops */
	struct file_lock	*i_flock;
	struct address_space	i_data;
#ifdef CONFIG_QUOTA
	struct dquot		*i_dquot[MAXQUOTAS];
#endif
	struct list_head	i_devices;
	union {
		struct pipe_inode_info	*i_pipe;
		struct block_device	*i_bdev;
		struct cdev		*i_cdev;
	};

	__u32			i_generation;

#ifdef CONFIG_FSNOTIFY
	__u32			i_fsnotify_mask; /* all events this inode cares about */
	struct hlist_head	i_fsnotify_marks;
#endif

#ifdef CONFIG_IMA
	atomic_t		i_readcount; /* struct files open RO */
#endif
	void			*i_private; /* fs or device private pointer */
};
```

与索引节点对象关联的方法也叫索引节点操作.它们由inode_operations结构来描述:

#### inode_operations

path: include/linux/fs.h
```
struct inode_operations {
	struct dentry * (*lookup) (struct inode *,struct dentry *, unsigned int);
	void * (*follow_link) (struct dentry *, struct nameidata *);
	int (*permission) (struct inode *, int);
	struct posix_acl * (*get_acl)(struct inode *, int);

	int (*readlink) (struct dentry *, char __user *,int);
	void (*put_link) (struct dentry *, struct nameidata *, void *);

	int (*create) (struct inode *,struct dentry *, umode_t, bool);
	int (*link) (struct dentry *,struct inode *,struct dentry *);
	int (*unlink) (struct inode *,struct dentry *);
	int (*symlink) (struct inode *,struct dentry *,const char *);
	int (*mkdir) (struct inode *,struct dentry *,umode_t);
	int (*rmdir) (struct inode *,struct dentry *);
	int (*mknod) (struct inode *,struct dentry *,umode_t,dev_t);
	int (*rename) (struct inode *, struct dentry *,
			struct inode *, struct dentry *);
	int (*setattr) (struct dentry *, struct iattr *);
	int (*getattr) (struct vfsmount *mnt, struct dentry *, struct kstat *);
	int (*setxattr) (struct dentry *, const char *,const void *,size_t,int);
	ssize_t (*getxattr) (struct dentry *, const char *, void *, size_t);
	ssize_t (*listxattr) (struct dentry *, char *, size_t);
	int (*removexattr) (struct dentry *, const char *);
	int (*fiemap)(struct inode *, struct fiemap_extent_info *, u64 start,
		      u64 len);
	int (*update_time)(struct inode *, struct timespec *, int);
	int (*atomic_open)(struct inode *, struct dentry *,
			   struct file *, unsigned open_flag,
			   umode_t create_mode, int *opened);
	int (*tmpfile) (struct inode *, struct dentry *, umode_t);
	int (*set_acl)(struct inode *, struct posix_acl *, int);
} ____cacheline_aligned;
```

文件对象
--------------------------------------------------------------------------------

文件对象描述进程怎样与一个打开的文件进行交互.文件对象是在文件打开时创建的,由一个
file结构组成.
**注意**: 文件对象在磁盘上没有对应的映像,一次file结构中没有设置"脏"字段来表示文件对象是否被修改.

path: include/linux/fs.h
```
struct file {
	union {
		struct llist_node	fu_llist;
		struct rcu_head 	fu_rcuhead;
	} f_u;
	struct path		f_path;
#define f_dentry	f_path.dentry
	struct inode		*f_inode;	/* cached value */
	const struct file_operations	*f_op;

	/*
	 * Protects f_ep_links, f_flags.
	 * Must not be taken from IRQ context.
	 */
	spinlock_t		f_lock;
	atomic_long_t		f_count;
	unsigned int 		f_flags;
	fmode_t			f_mode;
	struct mutex		f_pos_lock;
	loff_t			f_pos;
	struct fown_struct	f_owner;
	const struct cred	*f_cred;
	struct file_ra_state	f_ra;

	u64			f_version;
#ifdef CONFIG_SECURITY
	void			*f_security;
#endif
	/* needed for tty driver, and maybe others */
	void			*private_data;

#ifdef CONFIG_EPOLL
	/* Used by fs/eventpoll.c to link all the hooks to this file */
	struct list_head	f_ep_links;
	struct list_head	f_tfile_llink;
#endif /* #ifdef CONFIG_EPOLL */
	struct address_space	*f_mapping;
#ifdef CONFIG_DEBUG_WRITECOUNT
	unsigned long f_mnt_write_state;
#endif
} __attribute__((aligned(4)));	/* lest something weird decides that 2 is OK */

```

每个文件系统都有其自己的文件操作集合,执行诸如读写文件这样的操作.当内核将一个索引节点装入内存时,
就会把指向这些文件操作的指针存放在file_operations结构中,该结构的地址存放在索引节点对象的i_fop字段中.
当进程打开这个文件的时候,VFS就用存放在索引节点的这个地址初始化新文件对象的f_op字段,使得对文件操作的
后续调用能够使用这些函数.

#### file_operations

```
struct file_operations {
	struct module *owner;
	loff_t (*llseek) (struct file *, loff_t, int);
	ssize_t (*read) (struct file *, char __user *, size_t, loff_t *);
	ssize_t (*write) (struct file *, const char __user *, size_t, loff_t *);
	ssize_t (*aio_read) (struct kiocb *, const struct iovec *, unsigned long, loff_t);
	ssize_t (*aio_write) (struct kiocb *, const struct iovec *, unsigned long, loff_t);
	int (*iterate) (struct file *, struct dir_context *);
	unsigned int (*poll) (struct file *, struct poll_table_struct *);
	long (*unlocked_ioctl) (struct file *, unsigned int, unsigned long);
	long (*compat_ioctl) (struct file *, unsigned int, unsigned long);
	int (*mmap) (struct file *, struct vm_area_struct *);
	int (*open) (struct inode *, struct file *);
	int (*flush) (struct file *, fl_owner_t id);
	int (*release) (struct inode *, struct file *);
	int (*fsync) (struct file *, loff_t, loff_t, int datasync);
	int (*aio_fsync) (struct kiocb *, int datasync);
	int (*fasync) (int, struct file *, int);
	int (*lock) (struct file *, int, struct file_lock *);
	ssize_t (*sendpage) (struct file *, struct page *, int, size_t, loff_t *, int);
	unsigned long (*get_unmapped_area)(struct file *, unsigned long, unsigned long, unsigned long, unsigned long);
	int (*check_flags)(int);
	int (*flock) (struct file *, int, struct file_lock *);
	ssize_t (*splice_write)(struct pipe_inode_info *, struct file *, loff_t *, size_t, unsigned int);
	ssize_t (*splice_read)(struct file *, loff_t *, struct pipe_inode_info *, size_t, unsigned int);
	int (*setlease)(struct file *, long, struct file_lock **);
	long (*fallocate)(struct file *file, int mode, loff_t offset,
			  loff_t len);
	int (*show_fdinfo)(struct seq_file *m, struct file *f);
};
```

目录项对象
--------------------------------------------------------------------------------

VFS把每个目录看作由若干子目录和文件组成的一个普通文件.然而一旦目录项被读入内存,VFS就把它转换成基于dentry结构的一个
目录项对象.对于进程查找的路径名中的每一个分量,内核都为其创建一个目录项对象;目录项对象将每个分量与其对应的索引节点相联系.
例如,在查找路径名/tmp/test时,内核为根目录"/"创建一个目录项对象,为根目录下的"tmp"项创建一个第二级目录项对象,为"test"项
创建一个第三级目录项对象.

**注意**: 目录项对象在磁盘上没有对应的映像,因此在dentry结构中不包括指出对该对象已经被修改的字段.目录项对象存放在名为"dentry_cache"
的slab分配器高速缓存中.

#### dentry

path: include/linux/dcache.h
```
struct dentry {
	/* RCU lookup touched fields */
	unsigned int d_flags;		/* protected by d_lock */
	seqcount_t d_seq;		/* per dentry seqlock */
	struct hlist_bl_node d_hash;	/* lookup hash list */
	struct dentry *d_parent;	/* parent directory */
	struct qstr d_name;
	struct inode *d_inode;		/* Where the name belongs to - NULL is
					 * negative */
	unsigned char d_iname[DNAME_INLINE_LEN];	/* small names */

	/* Ref lookup also touches following */
	struct lockref d_lockref;	/* per-dentry lock and refcount */
        /* 目录项方法 */
	const struct dentry_operations *d_op;
        /* 文件的超级块对象 */
	struct super_block *d_sb;	/* The root of the dentry tree */
	unsigned long d_time;		/* used by d_revalidate */
	void *d_fsdata;			/* fs-specific data */

	struct list_head d_lru;		/* LRU list */
	/*
	 * d_child and d_rcu can share memory
	 */
	union {
		struct list_head d_child;	/* child of parent list */
	 	struct rcu_head d_rcu;
	} d_u;
	struct list_head d_subdirs;	/* our children */
	struct hlist_node d_alias;	/* inode alias list */
};
```

与目录项对象关联的方法称为目录项操作.这些方法由dentry_operations结构加以描述.

#### dentry_operations

path: linux/fs/dcache.h
```
struct dentry_operations {
	int (*d_revalidate)(struct dentry *, unsigned int);
	int (*d_weak_revalidate)(struct dentry *, unsigned int);
	int (*d_hash)(const struct dentry *, struct qstr *);
	int (*d_compare)(const struct dentry *, const struct dentry *,
			unsigned int, const char *, const struct qstr *);
	int (*d_delete)(const struct dentry *);
	void (*d_release)(struct dentry *);
	void (*d_prune)(struct dentry *);
	void (*d_iput)(struct dentry *, struct inode *);
	char *(*d_dname)(struct dentry *, char *, int);
	struct vfsmount *(*d_automount)(struct path *);
	int (*d_manage)(struct dentry *, bool);
} ____cacheline_aligned;
```

与进程相关的文件
--------------------------------------------------------------------------------

每个进程都有它当前的工作目录和它自己的根目录.这仅仅是内核用来表示进程与文件系统相互作用
所必须维护的数据中的两个例子,类型为fs_struct的整个数据结构就用于此目的.且每个进程描述符
的fs字段就指向进程的fs_struct结构.

#### fs_struct

path: include/linux/fs_struct.h
```
struct fs_struct {
	int users;
	spinlock_t lock;
	seqcount_t seq;
	int umask;
	int in_exec;
	struct path root, pwd;
};
```

#### path

path: include/linux/path.h
```
ostruct path {
	struct vfsmount *mnt;
	struct dentry *dentry;
};
```

命名空间
--------------------------------------------------------------------------------

在传统的Unix系统中,只有一个已安装文件系统树: 从系统的根文件系统开始,每个进程通过指定合适的路径名可以访问
已安装文件系统的任何文件. 从这个方面考虑: Linux 2.6更加精确, 每个进程可拥有自己的已安装文件系统树--叫做进程
的命名空间.
通常大多数进程共享同一个命名空间,即位于系统的根文件系统且被init进程使用的已安装文件系统树.不过,如果clone
系统调用以CLONE_NEWNS标志创建一个进程,那么进程将获得一个新的命名空间.这个新的命名空间随后由子进程继承.
当进程安装或卸载一个文件系统时,仅修改它的命名空间.因此,所做的修改对共享同一命名空间的所有进程都是可见的,并且
也只对它们可见.进程甚至可通过使用Linux特有的pivot_root()系统调用来改变它们命名空间的根文件系统.
进程的命名空间由进程描述符的nsproxy字段指向的nsproxy结构描述.

#### nsproxy

path: include/linux/nsproxy.h
```
/*
 * A structure to contain pointers to all per-process
 * namespaces - fs (mount), uts, network, sysvipc, etc.
 *
 * The pid namespace is an exception -- it's accessed using
 * task_active_pid_ns.  The pid namespace here is the
 * namespace that children will use.
 *
 * 'count' is the number of tasks holding a reference.
 * The count for each namespace, then, will be the number
 * of nsproxies pointing to it, not the number of tasks.
 *
 * The nsproxy is shared by tasks which share all namespaces.
 * As soon as a single namespace is cloned or unshared, the
 * nsproxy is copied.
 */
struct nsproxy {
	atomic_t count;
	struct uts_namespace *uts_ns;
	struct ipc_namespace *ipc_ns;
	struct mnt_namespace *mnt_ns;
	struct pid_namespace *pid_ns_for_children;
	struct net 	     *net_ns;
};
```

#### mnt_namespace

path: fs/mount.h
```
struct mnt_namespace {
	atomic_t		count;
	unsigned int		proc_inum;
	struct mount *	root;
	struct list_head	list;
	struct user_namespace	*user_ns;
	u64			seq;	/* Sequence number to prevent loops */
	wait_queue_head_t poll;
	int event;
};
```

Blog
--------------------------------------------------------------------------------
http://www.ibm.com/developerworks/cn/linux/l-linux-filesystem/ (Linux文件系统剖析)