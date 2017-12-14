struct dentry
========================================

由于块设备速度较慢，可能需要很长时间才能找到与一个文件名关联的
inode。即使设备数据已经在页缓存中，仍然每次都会重复整个查找
操作（简直荒谬）。Linux使用目录项缓存（简称dentry缓存）来快速
访问此前的查找操作的结果。该缓存围绕着struct dentry建立.
在VFS连同文件系统实现读取的一个目录项（目录或文件）的数据之后，
则创建一个dentry实例，以缓存找到的数据。

d_flags
----------------------------------------

path: include/linux/dcache.h
```
struct dentry {
    /* RCU lookup touched fields */
    unsigned int d_flags;        /* protected by d_lock */
```

d_flags可以包含几个标志，标志在include/linux/dcache.h中定义。
但其中只有两个与我们的目的相关：DCACHE_DISCONNECTED指定一个
dentry当前没有连接到超级块的dentry树。DCACHE_UNHASHED表明该
dentry实例没有包含在任何inode的散列表中。要注意，这两个标志
是彼此完全独立的。

d_seq
----------------------------------------

```
    seqcount_t d_seq;        /* per dentry seqlock */
```

d_hash
----------------------------------------

```
    struct hlist_bl_node d_hash;    /* lookup hash list */
```

The d_hash field of a dentry links the dentry into
the list of dentries for filenames with a given hash value
with list head dentry_hashtable[hashvalue] defined in dcache.c.
This list is used in d_lookup() to find a dentry with given name
and parent. It is used in d_validate() to find a dentry with
known hash and parent.
	[The present code takes the parent into account when
	 computing a hash. Not doing this would make the code
	 simpler and faster, possibly at the expense of a few
	 more collisions. Has anyone investigated this?]
The d_hash field is an empty list when the file is a mount point
(cf. d_validate) or has been deleted, or when the dentry was
dropped for some other reason.


d_add(D,I) will put D into its hash chain and provide it
with the inode I. It is called by all filesystem lookup routines.

d_drop(D) will remove D from its hash chain. A dentry is called
`unhashed' when its d_hash field is an empty list.
Sometimes dentries are dropped temporarily to make sure
no lookup will find them. The general routine vfs_rmdir(I,D)
will drop D if d_count=2, so that all filesystem rmdir()
routines can return -EBUSY when D still occurs in the hash list.
The filesystem routines for unlink and rmdir call d_delete()
which again calls d_drop().

[The d_hash field is referred to in many places that should
not know about its existence, in the phrase
	if (list_empty(&dentry->d_hash)) ...
No doubt there should be a line
	#define unhashed(d)	(list_empty(&(d)->d_hash))
in dcache.h, together with a comment describing the semantics
of being unhashed. Then all these occurrences of d_hash can
be removed. Next, d_drop() should be renamed d_unhash().]

The dentry for the root of a mounted filesystem is returned by
d_alloc_root() and is unhashed.

d_parent
----------------------------------------

```
    struct dentry *d_parent;    /* parent directory */
```

d_parent是一个指针，指向当前结点父目录的dentry实例，当前的
dentry实例即位于父目录的d_subdirs链表中。对于根目录（没有父
目录），d_parent指向其自身的dentry实例。

d_name
----------------------------------------

```
    struct qstr d_name;
```

d_name指定了文件的名称。qstr是一个内核字符串的包装器。它存储了
实际的char *字符串以及字符串长度和散列值，这使得更容易处理查找
工作。这里并不存储绝对路径，只有路径的最后一个分量，例如对
/usr/bin/emacs只存储emacs，因为上述链表结构已经映射了目录结构。

d_inode
----------------------------------------

```
    struct inode *d_inode;        /* Where the name belongs to - NULL is
                     * negative */
```

d_inode是指向相关的inode实例的指针。如果dentry对象是为一个不存在
的文件名建立的，则d_inode为NULL指针。这有助于加速查找不存在的文
件名，通常情况下，这与查找实际存在的文件名同样耗时。

d_iname
----------------------------------------

```
    unsigned char d_iname[DNAME_INLINE_LEN];    /* small names */
```

如果文件名只由少量字符组成，则保存在d_iname中，而不是dname中，
以加速访问。短文件名的长度上限由DNAME_INLINE_NAME_LEN指定，
最多不超过16个字符。但内核有时能够容纳更长的文件名，因为该成
员位于结构的末尾，而容纳该数据的缓存行可能仍然有可用空间
（这取决于体系结构和处理器类型）。

d_lockref
----------------------------------------

```
    /* Ref lookup also touches following */
    struct lockref d_lockref;    /* per-dentry lock and refcount */
```

d_op
----------------------------------------

```
    const struct dentry_operations *d_op;
```

d_op指向一个结构，其中包含了各种函数指针，提供对dentry对象的
各种操作。这些操作必须由底层文件系统实现。

https://github.com/novelinux/linux-4.x.y/blob/master/include/linux/dcache.h/struct_dentry_operations.md

d_sb
----------------------------------------

```
    struct super_block *d_sb;    /* The root of the dentry tree */
```

d_sb是一个指针，指向dentry对象所属文件系统超级块的实例。该指针
使得各个dentry实例散布到可用的（已装载的）文件系统。由于每个
超级块结构都包含了一个指针，指向该文件系统装载点对应目录的
dentry实例，因此dentry组成的树可以划分为几个子树。

d_time
----------------------------------------

```
    unsigned long d_time;        /* used by d_revalidate */
    void *d_fsdata;            /* fs-specific data */
```

## d_lru

```
    struct list_head d_lru;        /* LRU list */
```

he simplest list is the one joining the d_lru fields of
dentries that had d_count = 0 at some point in time.
The list head is the variable dentry_unused defined in dcache.c.
The number of elements in this list is dentry_stat.nr_unused.
There are no references to the d_lru field outside dcache.[ch].

Note that d_count is incremented by dget(), invoked by d_lookup(),
without removing the dentry from the LRU list. Thus, anyone hoping
to find unused dentries on this list must first check d_count.
If a dentry is not on the LRU list, its d_lru field is an
empty list (initialized by d_alloc()).

dput(D) tries to get rid of D altogether when d_count = 0, but
puts D at the head of the LRU list if it is still on the hash list.
Thus, every D with d_count = 0 will be on the LRU list.

select_dcache(ict,pct) removes D with d_count > 0 from the
LRU list, and moves D that are ready to be sacrificed for memory
to the end of the list. (If ict and/or pct is given, then we are
satisfied when the selected D's involve ict inodes or pct pages.)

prune_dcache(ct) removes D with d_count > 0 from the LRU list,
and frees unused D, stopping when ct of them have been freed.

shrink_dcache_sb(sb) removes all unused D with given superblock
from the LRU list.

select_parent(D) move all unused descendants of D to the end
of the LRU list.

d_child, d_subdirs
----------------------------------------

```
    struct list_head d_child;    /* child of parent list */
    struct list_head d_subdirs;    /* our children */
```

各个dentry实例组成了一个网络，与文件系统的结构形成一定的映射
关系。与给定目录下的所有文件和子目录相关联的den-try实例，
都归入到d_subdirs链表（在目录对应的dentry实例中）。子结点的
d_child成员充当链表元素。

As already noted, the names are terrible. The d_child field
does not refer to a child but to a sibling, and the d_subdirs
field does not refer to a subdirectory but to a child, directory
or not. These two fields form a threaded tree: the d_subdirs field
points to the first child, and the d_child field is member of the
circularly linked list of all children of one parent.

To be more precise: this circularly linked list of all children
of one parent P passes through the d_child fields of all children
and through the d_subdirs field of the parent P.

union
----------------------------------------

```
    /*
     * d_alias and d_rcu can share memory
     */
    union {
        struct hlist_node d_alias;    /* inode alias list */
         struct rcu_head d_rcu;
    } d_u;
};
```

### d_alias

d_alias用作链表元素，以连接表示相同文件的各个dentry对象。
在利用硬链接用两个不同名称表示同一文件时，会发生这种情况。
对应于文件的inode的i_dentry成员用作该链表的表头。各个dentry
对象通过d_alias连接到该链表中。

Somewhat similar to the above, where we had a circularly linked list
with one special element, we here have a circularly linked list
passing through the d_alias field of all dentries that are aliases
of one inode, and through the i_dentry field of the inode.

The dentry is added to this list by d_instantiate().
It is removed again by dentry_iput() which is called by dput()
and d_delete().

### d_rcu