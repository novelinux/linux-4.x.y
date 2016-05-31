kunmap_high
========================================

Arguments
----------------------------------------

path: mm/highmem.c
```
/**
 * kunmap_high - unmap a highmem page into memory
 * @page: &struct page to unmap
 *
 * If ARCH_NEEDS_KMAP_HIGH_GET is not defined then this may be called
 * only from user context.
 */
void kunmap_high(struct page *page)
{
    unsigned long vaddr;
    unsigned long nr;
    unsigned long flags;
    int need_wakeup;
    unsigned int color = get_pkmap_color(page);
    wait_queue_head_t *pkmap_map_wait;
```

page_address
----------------------------------------

```
    lock_kmap_any(flags);
    vaddr = (unsigned long)page_address(page);
    BUG_ON(!vaddr);
    nr = PKMAP_NR(vaddr);
```

scan pkmap_count
----------------------------------------

扫描整个pkmap_count数组。计数器值为1的项设置为0，从页表删除相关的项，最后删除该映射。

```
    /*
     * A count must never go down to zero
     * without a TLB flush!
     */
    need_wakeup = 0;
    switch (--pkmap_count[nr]) {
    case 0:
        BUG();
    case 1:
        /*
         * Avoid an unnecessary wake_up() function call.
         * The common case is pkmap_count[] == 1, but
         * no waiters.
         * The tasks queued in the wait-queue are guarded
         * by both the lock in the wait-queue-head and by
         * the kmap_lock.  As the kmap_lock is held here,
         * no need for the wait-queue-head's lock.  Simply
         * test if the queue is empty.
         */
        pkmap_map_wait = get_pkmap_wait_queue_head(color);
        need_wakeup = waitqueue_active(pkmap_map_wait);
    }
    unlock_kmap_any(flags);

    /* do wake-up, if needed, race-free outside of the spin lock */
    if (need_wakeup)
        wake_up(pkmap_map_wait);
}
```