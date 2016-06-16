struct address_space
========================================

path: include/linux/fs.h
```
struct address_space {
    struct inode        *host;        /* owner: inode, block_device */
    struct radix_tree_root    page_tree;    /* radix tree of all pages */
    spinlock_t        tree_lock;    /* and lock protecting it */
    atomic_t        i_mmap_writable;/* count VM_SHARED mappings */
    struct rb_root        i_mmap;        /* tree of private and shared mappings */
    struct rw_semaphore    i_mmap_rwsem;    /* protect tree, count, list */
    /* Protected by tree_lock together with the radix tree */
    unsigned long        nrpages;    /* number of total pages */
    unsigned long        nrshadows;    /* number of shadow entries */
    pgoff_t            writeback_index;/* writeback starts here */
    const struct address_space_operations *a_ops;    /* methods */
    unsigned long        flags;        /* error bits/gfp mask */
    spinlock_t        private_lock;    /* for use by the address_space */
    struct list_head    private_list;    /* ditto */
    void            *private_data;    /* ditto */
} __attribute__((aligned(sizeof(long))));
```