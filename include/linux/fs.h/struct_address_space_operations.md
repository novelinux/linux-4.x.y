struct address_space_operations
========================================

文件的内存映射可以认为是两个不同的地址空间之间的映射，以简化（系统）程序员的工作
。
一个地址空间是用户进程的虚拟地址空间，另一个是文件系统所在的地址空间。在内核创建一个映射时，必须建立两个地址空间之间的关联，以支持二者以读写请求的形式通信。

vm_operations_struct结构即用于完成该工作，它提供了一个操作来读取已经映射到虚拟地址空间、
但其内容尚未进入物理内存的页。但该操作不了解映射类型或其性质的相关信息。由于存在许多种类
的文件映射（不同类型文件系统上的普通文件、设备文件等），因此需要更多的信息。实际上，内核
需要更详细地说明数据源所在的地址空间。

writepage
----------------------------------------

path: include/linux/fs.h
```
struct address_space_operations {
    int (*writepage)(struct page *page, struct writeback_control *wbc);
```

writepage将一页的内容从物理内存写回到块设备上对应的位置，以便永久地保存更改的内容。

readpage
----------------------------------------

```
    int (*readpage)(struct file *, struct page *);
```

readpage从潜在的块设备读取一页到物理内存中。read-pages执行的任务相同，但一次读取几页。

writepages
----------------------------------------

```
    /* Write back some dirty pages from this mapping. */
    int (*writepages)(struct address_space *, struct writeback_control *);
```

set_page_dirty
----------------------------------------

```
    /* Set a page dirty.  Return true if this dirtied it */
    int (*set_page_dirty)(struct page *page);
```

set_page_dirty表示一页的内容已经改变，即与块设备上的原始内容不再匹配。

readpages
----------------------------------------

```
    int (*readpages)(struct file *filp, struct address_space *mapping,
            struct list_head *pages, unsigned nr_pages);

    int (*write_begin)(struct file *, struct address_space *mapping,
                loff_t pos, unsigned len, unsigned flags,
                struct page **pagep, void **fsdata);
    int (*write_end)(struct file *, struct address_space *mapping,
                loff_t pos, unsigned len, unsigned copied,
                struct page *page, void *fsdata);

    /* Unfortunately this kludge is needed for FIBMAP. Don't use it */
    sector_t (*bmap)(struct address_space *, sector_t);
    void (*invalidatepage) (struct page *, unsigned int, unsigned int);
    int (*releasepage) (struct page *, gfp_t);
    void (*freepage)(struct page *);
    ssize_t (*direct_IO)(struct kiocb *, struct iov_iter *iter, loff_t offset);
    /*
     * migrate the contents of a page to the specified target. If
     * migrate_mode is MIGRATE_ASYNC, it must not block.
     */
    int (*migratepage) (struct address_space *,
            struct page *, struct page *, enum migrate_mode);
    int (*launder_page) (struct page *);
    int (*is_partially_uptodate) (struct page *, unsigned long,
                    unsigned long);
    void (*is_dirty_writeback) (struct page *, bool *, bool *);
    int (*error_remove_page)(struct address_space *, struct page *);

    /* swapfile support */
    int (*swap_activate)(struct swap_info_struct *sis, struct file *file,
                sector_t *span);
    void (*swap_deactivate)(struct file *file);
};
```
