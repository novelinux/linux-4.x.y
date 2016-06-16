struct dentry_operations
========================================

d_revalidate
----------------------------------------

path: include/linux/dcache.h
```
struct dentry_operations {
    int (*d_revalidate)(struct dentry *, unsigned int);
    int (*d_weak_revalidate)(struct dentry *, unsigned int);
```

d_revalidate对网络文件系统特别重要。它检查内存中的各个dentry对象构成的结构是否仍然能够反映
当前文件系统中的情况。因为网络文件系统并不直接关联到内核/VFS，所有信息都必须通过网络连接收集，
可能由于文件系统在存储端的改变，致使某些dentry不再有效。该函数用于确保一致性。

d_hash
----------------------------------------

```
    int (*d_hash)(const struct dentry *, struct qstr *);
```

d_hash计算散列值，该值用于将对象放置到dentry散列表中。

d_compare
----------------------------------------

```
    int (*d_compare)(const struct dentry *, const struct dentry *,
            unsigned int, const char *, const struct qstr *);
```

d_compare比较两个dentry对象的文件名。尽管VFS只执行简单的字符串比较，但文件系统可以替换默认实现，
以适合自身的需求。例如，FAT实现中的文件名是不区分大小写的。因为不区分大写字母和小写字母，所以
简单的字符串匹配将返回错误的结果。在这种情况下必须提供一个特定于FAT的函数。

d_delete
----------------------------------------

```
    int (*d_delete)(const struct dentry *);
```

在最后一个引用已经移除（d_count到达0时）后，将调用d_delete。

d_release
----------------------------------------

```
    void (*d_release)(struct dentry *);
```

在最后删除一个dentry对象之前，将调用d_release。d_release和d_delete的两个默认实现什么都不做。

d_prune
----------------------------------------

```
    void (*d_prune)(struct dentry *);
```

d_iput
----------------------------------------

```
    void (*d_iput)(struct dentry *, struct inode *);
```

d_iput从一个不再使用的dentry对象中释放inode（在默认的情况下，将inode的使用计数器减1，计数器
到达0后，将inode从各种链表中移除）。

d_name
----------------------------------------

```
    char *(*d_dname)(struct dentry *, char *, int);
    struct vfsmount *(*d_automount)(struct path *);
    int (*d_manage)(struct dentry *, bool);
    struct inode *(*d_select_inode)(struct dentry *, unsigned);
} ____cacheline_aligned;
```