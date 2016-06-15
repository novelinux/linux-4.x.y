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

    struct list_head d_lru;        /* LRU list */
```

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

### d_rcu