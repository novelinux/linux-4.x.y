page_is_buddy
========================================

page_is_buddy确保属于伙伴的所有页都是空闲的，并包含在伙伴系统中,以便进行合并.

Comments
----------------------------------------

path: mm/page_alloc.c
```
/*
 * This function checks whether a page is free && is the buddy
 * we can do coalesce a page and its buddy if
 * (a) the buddy is not in a hole &&
 * (b) the buddy is in the buddy system &&
 * (c) a page and its buddy have the same order &&
 * (d) a page and its buddy are in the same zone.
 *
 * For recording whether a page is in the buddy system, we set ->_mapcount
 * PAGE_BUDDY_MAPCOUNT_VALUE.
 * Setting, clearing, and testing _mapcount PAGE_BUDDY_MAPCOUNT_VALUE is
 * serialized by zone->lock.
 *
 * For recording page's order, we use page_private(page).
 */
```

Arguments
----------------------------------------

```
static inline int page_is_buddy(struct page *page, struct page *buddy,
                            unsigned int order)
{
    if (!pfn_valid_within(page_to_pfn(buddy)))
        return 0;

    if (page_is_guard(buddy) && page_order(buddy) == order) {
        if (page_zone_id(page) != page_zone_id(buddy))
            return 0;

        VM_BUG_ON_PAGE(page_count(buddy) != 0, buddy);

        return 1;
    }
```

PageBuddy
----------------------------------------

```
    if (PageBuddy(buddy) && page_order(buddy) == order) {
        /*
         * zone check is done late to avoid uselessly
         * calculating zone/node ids for pages that could
         * never merge.
         */
        if (page_zone_id(page) != page_zone_id(buddy))
            return 0;

        VM_BUG_ON_PAGE(page_count(buddy) != 0, buddy);

        return 1;
    }
    return 0;
}
```

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/page-flags.h/PageBuddy.md
