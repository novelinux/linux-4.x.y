wait_on_page_xxx
========================================

很多情况下，需要等待页的状态改变，然后才能恢复工作。内核提供了两个辅助函数，对此很有用处：

path: include/linux/pagemap.h
```
/*
 * Wait for a page to be unlocked.
 *
 * This must be called with the caller "holding" the page,
 * ie with increased "page->count" so that the page won't
 * go away during the wait..
 */
static inline void wait_on_page_locked(struct page *page)
{
    if (PageLocked(page))
        wait_on_page_bit(page, PG_locked);
}

/*
 * Wait for a page to complete writeback
 */
static inline void wait_on_page_writeback(struct page *page)
{
    if (PageWriteback(page))
        wait_on_page_bit(page, PG_writeback);
}
```

假定内核的一部分在等待一个被锁定的页面，直至页面解锁。wait_on_page_locked提供了该功能。
在页面锁定的情况下调用该函数，内核将进入睡眠, 在页解锁之后，睡眠进程被自动唤醒并继续工作。
wait_on_page_writeback的工作方式类似，该函数会等待到与页面相关的所有待决回写操作结束，
将页面包含的数据同步到块设备（例如，硬盘）为止。