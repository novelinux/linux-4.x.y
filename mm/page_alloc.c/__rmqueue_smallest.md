__rmqueue_smallest
========================================

Arguments
----------------------------------------

path: mm/page_alloc.c
```
/*
 * Go through the free lists for the given migratetype and remove
 * the smallest available page from the freelists
 */
static inline
struct page *__rmqueue_smallest(struct zone *zone, unsigned int order,
                        int migratetype)
{
    unsigned int current_order;
    struct free_area *area;
    struct page *page;
```

Traverse
----------------------------------------

__rmqueue_smallest的实现不是很长。本质上，它由一个循环组成，按递增顺序遍历内存域的
各个特定迁移类型的空闲页列表，直至找到合适的一项。

搜索从指定分配阶对应的项开始。小的内存区无用，因为分配的页必须是连续的。我们知道给定
分配阶的所有页又再分成对应于不同迁移类型的列表，在其中需要选择正确的一项。

检查适当大小的内存块非常简单。如果检查的列表中有一个元素，那么它就是可用的，因为其中包含了
所需数目的连续页。否则，内核将选择下一个更高分配阶，并进行类似的搜索。

在用list_del从链表移除一个内存块之后,要注意,必须将struct free_area的nr_free成员减1。

```
    /* Find a page of the appropriate size in the preferred list */
    for (current_order = order; current_order < MAX_ORDER; ++current_order) {
        area = &(zone->free_area[current_order]);
        if (list_empty(&area->free_list[migratetype]))
            continue;

        page = list_entry(area->free_list[migratetype].next,
                            struct page, lru);
        list_del(&page->lru);
```

### rmv_page_order

rmv_page_order是一个辅助函数，从页标志删除PG_buddy位，表示该页不再包含于伙伴系统中，
并将struct page的private成员设置为0。

```
        rmv_page_order(page);
        area->nr_free--;
```

### expand

如果需要分配的内存块长度小于所选择的连续页范围，即如果因为没有更小的适当内存块可用，
而从较高的分配阶分配了一块内存，那么该内存块必须按照伙伴系统的原理分裂成小的块。
这是通过expand函数完成的。

```
        expand(zone, page, order, current_order, area, migratetype);
        set_pcppage_migratetype(page, migratetype);
        return page;
    }

    return NULL;
}
```

https://github.com/novelinux/linux-4.x.y/blob/master/mm/page_alloc.c/expand.md
