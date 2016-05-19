__rmqueue
========================================

内核使用了__rmqueue函数，该函数充当进入伙伴系统核心的看门人.

Arguments
----------------------------------------

path: mm/page_alloc.c
```
/*
 * Do the hard work of removing an element from the buddy allocator.
 * Call me with the zone->lock already held.
 */
static struct page *__rmqueue(struct zone *zone, unsigned int order,
                        int migratetype)
{
    struct page *page;
```

__rmqueue_smallest
----------------------------------------

```
retry_reserve:
    page = __rmqueue_smallest(zone, order, migratetype);
```

根据传递进来的用于获取页的内存域、分配阶、迁移类型，__rmqueue_smalles扫描页的列表，
直至找到适当的连续内存块。

https://github.com/novelinux/linux-4.x.y/blob/master/mm/page_alloc.c/__rmqueue_smallest.md

__rmqueue_cma_fallback
----------------------------------------

果在特定的迁移类型列表上没有连续内存区可用，则__rmqueue_smallest返回NULL指针。内核接下来根据
备用次序，尝试使用其他迁移类型的列表满足分配请求。如果migratetype指定为MIGRATE_MOVABLE,
则该任务委托给__rmqueue_cma_fallback，否则委托给__rmqueue_fallback函数来实现.

```
    if (unlikely(!page) && migratetype != MIGRATE_RESERVE) {
        if (migratetype == MIGRATE_MOVABLE)
            page = __rmqueue_cma_fallback(zone, order);
```

https://github.com/novelinux/linux-4.x.y/blob/master/mm/page_alloc.c/__rmqueue_cma_fallback.md

__rmqueue_fallback
----------------------------------------

```
        if (!page)
            page = __rmqueue_fallback(zone, order, migratetype);
```

https://github.com/novelinux/linux-4.x.y/blob/master/mm/page_alloc.c/__rmqueue_fallback.md

retry_reserve
----------------------------------------

```
        /*
         * Use MIGRATE_RESERVE rather than fail an allocation. goto
         * is used because __rmqueue_smallest is an inline function
         * and we want just one call site
         */
        if (!page) {
            migratetype = MIGRATE_RESERVE;
            goto retry_reserve;
        }
    }

    trace_mm_page_alloc_zone_locked(page, order, migratetype);
    return page;
}
```