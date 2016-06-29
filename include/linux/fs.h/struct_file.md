struct file
========================================

union
----------------------------------------

path: include/linux/fs.h
```
struct file {
    union {
        struct llist_node    fu_llist;
        struct rcu_head     fu_rcuhead;
    } f_u;
```

f_path
----------------------------------------

```
    struct path        f_path;
```

f_path封装了下面两部分信息：

* 文件名和inode之间的关联；
* 文件所在文件系统的有关信息。

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/path.h/struct_path.md

f_inode
----------------------------------------

```
    struct inode       *f_inode;    /* cached value */
```

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/fs.h/struct_inode.md

f_op
----------------------------------------

```
    const struct file_operations    *f_op;
```

f_op指定了文件操作调用的各个函数.

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/fs.h/struct_file_operations.md

f_lock
----------------------------------------

```
    /*
     * Protects f_ep_links, f_flags.
     * Must not be taken from IRQ context.
     */
    spinlock_t        f_lock;
```

f_count
----------------------------------------

```
    atomic_long_t        f_count;
```

f_flags
----------------------------------------

```
    unsigned int         f_flags;
```

f_flags指定了在open系统调用时传递的额外的标志。

f_mode
----------------------------------------

```
    fmode_t            f_mode;
```

打开文件时传递的模式参数（通常指定读、写或读写访问模式）保存在
f_mode字段中。

f_pos_lock
----------------------------------------

```
    struct mutex        f_pos_lock;
```

f_pos
----------------------------------------

```
    loff_t            f_pos;
```

文件位置指针的当前值（对于顺序读取操作或读取文件特定部分的操作，
都很重要）保存在f_pos变量中，表示与文件起始处的字节偏移。

f_owner
----------------------------------------

```
    struct fown_struct    f_owner;
```

f_owner包含了处理该文件的进程有关的信息（因而也确定了SIGIO信号
发送的目标PID，以实现异步输入输出）。

f_cred
----------------------------------------

```
    const struct cred    *f_cred;
```

f_ra
----------------------------------------

```
    struct file_ra_state    f_ra;
```

预读特征保存在f_ra。这些值指定了在实际请求文件数据之前，
是否预读文件数据、如何预读（预读可以提高系统性能）。

f_version
----------------------------------------

```
    u64            f_version;
```

f_version由文件系统使用，以检查一个file实例是否仍然与相关的
inode内容兼容。这对于确保已缓存对象的一致性很重要。

f_security
----------------------------------------

```
#ifdef CONFIG_SECURITY
    void            *f_security;
#endif
```

private_data
----------------------------------------

```
    /* needed for tty driver, and maybe others */
    void            *private_data;
```

CONFIG_EPOLL
----------------------------------------

```
#ifdef CONFIG_EPOLL
    /* Used by fs/eventpoll.c to link all the hooks to this file */
    struct list_head    f_ep_links;
    struct list_head    f_tfile_llink;
#endif /* #ifdef CONFIG_EPOLL */
```

f_mapping
----------------------------------------

每个打开文件（和每个块设备，因为这些也可以通过设备文件进行内存映射）都表示为struct file
的一个实例。该结构包含了一个指向地址空间对象struct address_space的指针。该对象是优先查
找树（prio tree）的基础，而文件区间与其映射到的地址空间之间的关联即通过优先树建立。

**Note**: 优先查找树（priority search tree）用于建立文件中的一个区域与该区域映射到的
所有虚拟地址空间之间的关联。

```
    struct address_space    *f_mapping;
} __attribute__((aligned(4)));    /* lest something weird decides that 2 is OK */
```

f_mapping指向属于文件相关的inode实例的地址空间映射。通常它
设置为inode->i_mapping，但文件系统或其他内核子系统可能会修改它.

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/fs.h/struct_address_space.md