__rmqueue_fallback
========================================

如果在特定的迁移类型列表上没有连续内存区可用，则__rmqueue_smallest返回NULL指针。
内核接下来根据备用次序，尝试使用其他迁移类型的列表满足分配请求。该任务委托给
__rmqueue_fallback。迁移类型的备用次序在fallbacks数组定义:

https://github.com/novelinux/linux-4.x.y/blob/master/mm/page_alloc.c/fallbacks.md

Arguments
----------------------------------------

path: mm/page_alloc.c
```
/* Remove an element from the buddy allocator from the fallback list */
static inline struct page *
__rmqueue_fallback(struct zone *zone, unsigned int order, int start_migratetype)
{
    struct free_area *area;
    unsigned int current_order;
    struct page *page;
    int fallback_mt;
    bool can_steal;
```

Traverse
----------------------------------------

首先，函数再一次遍历各个分配阶的列表：

但不只是相同的迁移类型，还要考虑备用列表中指定的不同迁移类型。请注意，该函数会按照分配阶从
大到小遍历！这与通常的策略相反，内核的策略是，如果无法避免分配迁移类型不同的内存块，那么就
分配一个尽可能大的内存块。如果优先选择更小的内存块，则会向其他列表引入碎片，因为不同迁移类型
的内存块将会混合起来，这显然不是我们想要的。

```
    /* Find the largest possible block of pages in the other list */
    for (current_order = MAX_ORDER-1;
                current_order >= order && current_order <= MAX_ORDER-1;
                --current_order) {
```

### find_suitable_fallback

```
        area = &(zone->free_area[current_order]);
        fallback_mt = find_suitable_fallback(area, current_order,
                start_migratetype, false, &can_steal);
        if (fallback_mt == -1)
            continue;
```

### steal_suitable_fallback

```
        page = list_entry(area->free_list[fallback_mt].next,
                        struct page, lru);
        if (can_steal)
            steal_suitable_fallback(zone, page, start_migratetype);

        /* Remove the page from the freelists */
        area->nr_free--;
        list_del(&page->lru);
        rmv_page_order(page);
```

https://github.com/novelinux/linux-4.x.y/blob/master/mm/page_alloc.c/steal_suitable_fallback.md

### expand

```
        expand(zone, page, order, current_order, area,
                    start_migratetype);
        /*
         * The pcppage_migratetype may differ from pageblock's
         * migratetype depending on the decisions in
         * find_suitable_fallback(). This is OK as long as it does not
         * differ for MIGRATE_CMA pageblocks. Those can be used as
         * fallback only via special __rmqueue_cma_fallback() function
         */
        set_pcppage_migratetype(page, start_migratetype);

        trace_mm_page_alloc_extfrag(page, order, current_order,
            start_migratetype, fallback_mt);

        return page;
    }

    return NULL;
}
```

最后内核将内存块从列表移除，并使用expand将其中未用的部分还给伙伴系统。
**注意**: 如果此前已经改变了迁移类型，那么expand将使用新的迁移类型。
否则，剩余部分将放置到原来的迁移列表上。