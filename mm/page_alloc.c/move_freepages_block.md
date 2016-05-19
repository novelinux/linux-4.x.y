move_freepages_block
========================================

path: mm/page_alloc.c
```
int move_freepages_block(struct zone *zone, struct page *page,
                int migratetype)
{
    unsigned long start_pfn, end_pfn;
    struct page *start_page, *end_page;

    start_pfn = page_to_pfn(page);
    start_pfn = start_pfn & ~(pageblock_nr_pages-1);
    start_page = pfn_to_page(start_pfn);
    end_page = start_page + pageblock_nr_pages - 1;
    end_pfn = start_pfn + pageblock_nr_pages - 1;

    /* Do not cross zone boundaries */
    if (!zone_spans_pfn(zone, start_pfn))
        start_page = page;
    if (!zone_spans_pfn(zone, end_pfn))
        return 0;
```

move_freepages
----------------------------------------

```
    return move_freepages(zone, start_page, end_page, migratetype);
}
```

https://github.com/novelinux/linux-4.x.y/tree/master/mm/page_alloc.c/move_freepages.md
