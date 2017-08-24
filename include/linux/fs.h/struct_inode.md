# struct inode

如何用数据结构表示目录的层次结构？inode对文件实现来说是一个主要的概念，
但它也用于实现目录。换句话说，目录只是一种特殊的文件，它必须正确地解释。
inode的成员可能分为下面两类。

* 描述文件状态的元数据. 例如，访问权限或上次修改的日期。

* 保存实际文件内容的数据段（或指向数据的指针）。就文本文件来说，用于保存文本。

在解释各个结构成员的语义之前，应该记住这里考察的in-ode结构是用于在内存中进行处理，
因而包含了一些实际介质上存储的inode所没有的成员。这些是由内核自身在从底层文件系统
读入信息时生成或动态建立。还有一些文件系统，如FAT和Reiserfs没有使用经典意义上的inode，
因此必须从其包含的数据中提取信息并生成这里给出的形式。

## i_mode

path: include/linux/fs.h
```
/*
 * Keep mostly read-only and often accessed (especially for
 * the RCU path lookup and 'stat' data) fields at the beginning
 * of the 'struct inode'
 */
struct inode {
    umode_t           i_mode;
```

i_mode文件类型和访问权限.为唯一地标识与一个设备文件关联的设备，
内核在i_mode中存储了文件类型（面向块，或者面向字符）.

## i_opflags

```
    unsigned short    i_opflags;
```

## i_uid, i_gid

```
    kuid_t            i_uid;
    kgid_t            i_gid;
```

i_uid和i_gid是与该文件相关的UID和GID.

## i_flags

```
    unsigned int      i_flags;

#ifdef CONFIG_FS_POSIX_ACL
    struct posix_acl    *i_acl;
    struct posix_acl    *i_default_acl;
#endif
```

## i_op

```
    const struct inode_operations    *i_op;
```

i_op数组与特定于inode的操作有关.inode_operations负责管理结构性的操作（例如删除一个文件）
和文件相关的元数据（例如，属性）。所有inode操作都集中到以下结构中：

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/fs.h/struct_inode_operations.md

## i_sb

```
    struct super_block    *i_sb;
```

## i_mapping

```
    struct address_space    *i_mapping;
```

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/fs.h/struct_address_space.md

## i_security

```
#ifdef CONFIG_SECURITY
    void            *i_security;
#endif
```

## i_ino

```
    /* Stat data, not accessed from path walking */
    unsigned long        i_ino;
```

每个VFS inode（对给定的文件系统）都由一个唯一的编号标识，保存在i_ino中。

## union

```
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
```

## i_rdev

```
    dev_t            i_rdev;
```

在inode表示设备文件时，则需要i_rdev。它表示与哪个设备进行通信。
要注意，i_rdev只是一个数字，不是数据结构！但这个数字包含的信息，
即足以找到有关目标设备, 对块设备，最终会找到struct block_device
的一个实例.如果inode表示设备特殊文件，那么i_rdev之后的匿名联合就
包含了指向设备专用数据结构的指针。

在i_rdev中存储了主从设备号。主从设备号在内核中合并为一种变量类型dev_t.
该数据类型的定义决不是持久不变的，在内核开发者认为必要时会进行修改。
因此，只应该使用两个辅助函数imajor和iminor来从i_rdev提取主设备号和
从设备号，这两个函数都只需要一个指向inode实例的指针作为参数。

### dev_t

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/types.h/dev_t.md

## i_size

```
    loff_t            i_size;
```

文件长度保存在i_size，按字节计算。

## i_atime, i_mtime, i_ctime

```
    struct timespec        i_atime;
    struct timespec        i_mtime;
    struct timespec        i_ctime;
```

i_atime,i_mtime,t_ctime分别存储了最后访问的时间、最后修改的时间、最后修改inode的时间。
修改意味着修改与inode相关的数据段内容。修改inode意味着修改inode结构自身(或文件的某个属性)，
这导致了i_ctime的改变。

## i_lock

```
    spinlock_t      i_lock;    /* i_blocks, i_bytes, maybe i_size */
    unsigned short  i_bytes;
    unsigned int    i_blkbits;
```

## i_blocks

```
    blkcnt_t        i_blocks;
```

i_blocks指定了文件按块计算的长度。该值是文件系统的特征，不属于文件自身。
在许多文件系统创建时，会选择一个块长度，作为在硬件介质上分配存储空间的
最小单位（Ext2文件系统的默认值是每块4 096字节，但可以选择更大或更小的值）。
因此，按块计算的文件长度，也可以根据文件的字节长度和文件系统块长度计算得出。
实际上没有这样做，为方便起见，该信息也归入到inode结构。

## i_size_seqcount

```
#ifdef __NEED_I_SIZE_ORDERED
    seqcount_t        i_size_seqcount;
#endif
```

## i_state

```
    /* Misc */
    unsigned long        i_state;
```

根据inode的状态，它可能有3种主要的情况:

* 1.inode存在于内存中，未关联到任何文件，也不处于活动使用状态;

* 2.inode结构在内存中，正在由一个或多个进程使用，通常表示一个文件。
两个计数器（i_count和i_nlink）的值都必须大于0。文件内容和inode
元数据都与底层块设备上的信息相同。也就是说，从上一次与存储介质
同步以来，该inode没有改变过。

* 3.inode处于活动使用状态。其数据内容已经改变，与存储介质上的内容不同。这种状态的inode被称作脏的。

* 4.第四种可能性出现得不那么频繁，一般是与一个超级块相关的所有inode都无效时。在检测到
可移动设备的介质改变时，此前使用的inode就都没有意义了，另外文件系统重新装载时也会发生
这种情况。在所有情况下，代码都结束于invalidate_inodes函数中，无效inode保存在一个本地
链表中，与VFS代码再没有关系了。

## i_mutex

```
    struct mutex        i_mutex;

    unsigned long        dirtied_when;    /* jiffies of first dirtying */
    unsigned long        dirtied_time_when;
```

## i_hash

```
    struct hlist_node    i_hash;
```

每个inode不仅出现在特定于状态的链表中，还在一个散列表中出现，以支持根据inode编号和
超级块快速访问inode，这两项的组合在系统范围内是唯一的。该散列表是一个数组，可以借助
于全局变量inode_hashtable来访问。

## i_io_list

```
    struct list_head    i_io_list;    /* backing dev IO list */
#ifdef CONFIG_CGROUP_WRITEBACK
    struct bdi_writeback    *i_wb;        /* the associated cgroup wb */

    /* foreign inode detection, see wbc_detach_inode() */
    int            i_wb_frn_winner;
    u16            i_wb_frn_avg_time;
    u16            i_wb_frn_history;
#endif
```

## i_lru

```
    struct list_head    i_lru;        /* inode LRU list */
```

## i_sb_list

```
    struct list_head    i_sb_list;
```

inode还通过一个特定于超级块的链表维护，表头是super_block->s_inodes。i_sb_list用作链表元素。

## union

```
    union {
        struct hlist_head    i_dentry;
        struct rcu_head        i_rcu;
    };
```

### i_dentry

在inode结构中有一个hash表struct hlist_head i_dentry结构，这个链表链接“被使用的”目录项，
当然，这些目录项的d_inode指针都指向同一个inode结构。这代表什么呢？

**表示一个索引节点可以对应多个目录项对象。**
分析：显然，要让一个索引节点表示多个目录项对象，肯定会使用文件链接，文件链接有两种类型，硬链接和符号链接（软链接）。
使用ls -i可以查看文件的inode。执行一些简单操作如下：

```
$ mkdir test_dir
```

然后执行:

```
mido:/data/local/tmp # mkdir test
mido:/data/local/tmp # ln test test_hardlink
ln: cannot create hard link from 'test' to 'test_hardlink': Operation not permitted
```

显然，上面的命令会失败，因为硬链接不能指向目录，否则在文件系统中会形成环，另外，硬链接还不能跨文件系统，为什么呢？看了下面的命令就知道。

```
mido:/data/local/tmp # touch tf
mido:/data/local/tmp # ln tf tf_hardlink
1|mido:/data/local/tmp # ls -i
23 tf 23 tf_hardlink
mido:/data/local/tmp # ln -s tf tf_symlink
mido:/data/local/tmp # ls -i
23 tf 23 tf_hardlink 24 tf_symlink
```
从最后一条命令可以看出，符号链接有不同的inode号，而硬链接文件tf_hardlink和文件tf的inode号一样，表示它们执行同一个inode结构。
由于inode是对于文件系统来说的，所以硬链接不能跨越文件系统，不同文件系统中的相同inode并不是同一个inode。而符号链接没有硬链接的如上两个限制。

inode结构中的i_dentry链表结构，把属于同一个inode的被使用的（dentry结构中的d_count大于0）目录项连接起来。
显然，这里的目录项肯定是使用硬链接的方式来表示的，但是硬链接不能指向目录！
这里是最容迷惑的地方：其实，不仅是目录才是目录项，文件也是目录项，看看前面对目录项的定义中的举例就知道了。

另外，在inode结构中嵌入的双向链表成员struct list_head i_dentry，并不是用来链接inode结构的，而是链接dentry结构的.


## i_version

```
    u64            i_version;
```

## i_count

```
    atomic_t        i_count;
```

i_count是一个使用计数器，指定访问该inode结构的进程数目。例如，进程通过fork复制自身时，
inode会由不同进程同时使用.

## i_dio_count

```
    atomic_t        i_dio_count;
    atomic_t        i_writecount;
#ifdef CONFIG_IMA
    atomic_t        i_readcount; /* struct files open RO */
#endif
```

## i_fop

```
    const struct file_operations    *i_fop;    /* former ->i_op->default_file_ops */
```

i_fop提供了文件操作。file_operations用于操作文件中包含的数据.

## i_flctx

```
    struct file_lock_context    *i_flctx;
    struct address_space    i_data;
```

## i_devices

```
    struct list_head    i_devices;
```

i_devices也与设备文件的处理有关联：利用该成员作为链表元素，使得块设备或字符设备可以维护
一个inode的链表，每个inode表示一个设备文件，通过设备文件可以访问对应的设备。尽管在很多
情况下每个设备一个设备文件就足够了，但还有很多种可能性。例如chroot造成的环境，其中一个
给定的块设备或字符设备可以通过多个设备文件，因而需要多个inode。

## union

```
    union {
        struct pipe_inode_info    *i_pipe;
        struct block_device    *i_bdev;
        struct cdev        *i_cdev;
        char            *i_link;
    };
```

### i_pipe

i_pipe包含了用于实现管道的inode的相关信息.

### i_bdev

i_bdev用于块设备.

### i_cdev

i_cdev用于字符设备。由于一个inode一次只能表示一种类型的设备.

### i_link

i_nlink也是一个计数器，记录使用该inode的硬链接总数。

链接（link）用于建立文件系统对象之间的联系。有两种类型的链接: 符号链接与硬链接。

* 符号连接

可以认为是“方向指针”（至少从用户程序来看是这样），表示某个文件存在于特定的位置。
当然我们都知道，实际的文件在其他地方。有时使用软链接来表示此类链接。这是因为
链接和链接目标彼此并未紧密耦合。链接可以认为是一个目录项，其中除了指向文件名的指针，
并不存在其他数据。目标文件删除时，符号链接仍然继续保持。对每个符号链接都使用了一个
独立的inode。相应inode的数据段包含一个字符串，给出了链接目标的路径。对于符号链接，
可以区分原始文件和链接。

* 硬链接

在硬链接已经建立后，无法区分哪个文件是原来的，哪个是后来建立的。在硬链接建立时，
创建的目录项使用了一个现存的inode编号。删除符号链接并不困难，但硬链接的处理有一点技巧。
我们假定硬链接（B）与原始文件（A）共享同一个inode。一个用户现在想要删除A。这通常会
销毁相关的inode连同其数据段，以便释放存储空间供后续使用。那么接下来B就不能继续访问了，
因为相关的inode和文件信息不再存在了。当然，这不是我们想要的行为。

在inode中加入一个计数器，即可防止这种情况。每次对文件创建一个硬链接时，都将计数器加1。
如果其中一个硬链接或原始文件被删除（不可能区分这两种情况），那么将计数器减1。只有在
计数器归0时，我们才能确认该inode不再使用，可以从系统删除。

## i_generation

```
    __u32            i_generation;

#ifdef CONFIG_FSNOTIFY
    __u32            i_fsnotify_mask; /* all events this inode cares about */
    struct hlist_head    i_fsnotify_marks;
#endif

    void            *i_private; /* fs or device private pointer */
};
```
