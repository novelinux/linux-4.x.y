move_freepages
========================================

move_freepages试图将包含2个页的整个内存块（包含当前将分配的内存块在内）转移到新的迁移列表。
但只有空闲页（即设置了PG_buddy标志位的页）才会移动。此外，move_freepages还会考虑到内存域的边界，
因此移动页的总数可能小于整个大内存块。

path: mm/page_alloc.c
```
/*
 * Move the free pages in a range to the free lists of the requested type.
 * Note that start_page and end_pages are not aligned on a pageblock
 * boundary. If alignment is required, use move_freepages_block()
 */
int move_freepages(struct zone *zone,
              struct page *start_page, struct page *end_page,
              int migratetype)
{
    struct page *page;
    unsigned long order;
    int pages_moved = 0;

#ifndef CONFIG_HOLES_IN_ZONE
    /*
     * page_zone is not safe to call in this context when
     * CONFIG_HOLES_IN_ZONE is set. This bug check is probably redundant
     * anyway as we check zone boundaries in move_freepages_block().
     * Remove at a later date when no bug reports exist related to
     * grouping pages by mobility
     */
    VM_BUG_ON(page_zone(start_page) != page_zone(end_page));
#endif

    for (page = start_page; page <= end_page;) {
        /* Make sure we are not inadvertently changing nodes */
        VM_BUG_ON_PAGE(page_to_nid(page) != zone_to_nid(zone), page);

        if (!pfn_valid_within(page_to_pfn(page))) {
            page++;
            continue;
        }

        if (!PageBuddy(page)) {
            page++;
            continue;
        }

        order = page_order(page);
        list_move(&page->lru,
              &zone->free_area[order].free_list[migratetype]);
        page += 1 << order;
        pages_moved += 1 << order;
    }

    return pages_moved;
}
```