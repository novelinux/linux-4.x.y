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

f_inode
----------------------------------------

```
    struct inode       *f_inode;    /* cached value */
```

f_op
----------------------------------------

```
    const struct file_operations    *f_op;
```

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

f_mode
----------------------------------------

```
    fmode_t            f_mode;
```

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

f_owner
----------------------------------------

```
    struct fown_struct    f_owner;
```

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

f_version
----------------------------------------

```
    u64            f_version;
```

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

```
    struct address_space    *f_mapping;
} __attribute__((aligned(4)));    /* lest something weird decides that 2 is OK */
```