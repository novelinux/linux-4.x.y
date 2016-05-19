steal_suitable_fallback
========================================

Arguments
----------------------------------------

path: mm/page_alloc.c
```
/*
 * This function implements actual steal behaviour. If order is large enough,
 * we can steal whole pageblock. If not, we first move freepages in this
 * pageblock and check whether half of pages are moved or not. If half of
 * pages are moved, we can change migratetype of pageblock and permanently
 * use it's pages as requested migratetype in the future.
 */
static void steal_suitable_fallback(struct zone *zone, struct page *page,
                              int start_type)
{
    int current_order = page_order(page);
    int pages;
```

change_pageblock_range
----------------------------------------

```
    /* Take ownership for orders >= pageblock_order */
    if (current_order >= pageblock_order) {
        change_pageblock_range(page, current_order, start_type);
        return;
    }
```

https://github.com/novelinux/linux-4.x.y/blob/master/mm/page_alloc.c/change_pageblock_range.md

move_freepages_block
----------------------------------------

```
    pages = move_freepages_block(zone, page, start_type);

    /* Claim the whole block if over half of it is free */
    /* 但如果大内存块有超过二分之一的部分是空闲的，接下来set_pageblock_migratetype将修改整个
     * 大内存块的迁移类型
     */
    if (pages >= (1 << (pageblock_order-1)) ||
            page_group_by_mobility_disabled)
        set_pageblock_migratetype(page, start_type);
}
```

https://github.com/novelinux/linux-4.x.y/blob/master/mm/page_alloc.c/move_freepages_block.md
