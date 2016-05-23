free_one_page
========================================

Arguments
----------------------------------------

path: mm/page_alloc.c
```
static void free_one_page(struct zone *zone,
                struct page *page, unsigned long pfn,
                unsigned int order,
                int migratetype)
{
    unsigned long nr_scanned;
    spin_lock(&zone->lock);
    nr_scanned = zone_page_state(zone, NR_PAGES_SCANNED);
    if (nr_scanned)
        __mod_zone_page_state(zone, NR_PAGES_SCANNED, -nr_scanned);

    if (unlikely(has_isolate_pageblock(zone) ||
        is_migrate_isolate(migratetype))) {
        migratetype = get_pfnblock_migratetype(page, pfn);
    }
```

__free_one_page
----------------------------------------

```
    __free_one_page(page, pfn, zone, order, migratetype);
    spin_unlock(&zone->lock);
}
```

https://github.com/novelinux/linux-4.x.y/tree/master/mm/page_alloc.c/__free_one_page.md