memmap_init_zone
========================================

初始化基于可移动性的分组, 在内存子系统初始化期间，memmap_init_zone负责处理内存域的page实例。
该函数完成了一些标准初始化工作.

Arguments
----------------------------------------

path: mm/page_alloc.c
```
/*
 * Initially all pages are reserved - free ones are freed
 * up by free_all_bootmem() once the early boot process is
 * done. Non-atomic initialization, single-pass.
 */
void __meminit memmap_init_zone(unsigned long size, int nid, unsigned long zone,
        unsigned long start_pfn, enum memmap_context context)
{
    pg_data_t *pgdat = NODE_DATA(nid);
    unsigned long end_pfn = start_pfn + size;
    unsigned long pfn;
    struct zone *z;
    unsigned long nr_initialised = 0;
```

Configure
----------------------------------------

```
    if (highest_memmap_pfn < end_pfn - 1)
        highest_memmap_pfn = end_pfn - 1;

    z = &pgdat->node_zones[zone];
    for (pfn = start_pfn; pfn < end_pfn; pfn++) {
        /*
         * There can be holes in boot-time mem_map[]s
         * handed to this function.  They do not
         * exist on hotplugged memory.
         */
        if (context == MEMMAP_EARLY) {
            if (!early_pfn_valid(pfn))
                continue;
            if (!early_pfn_in_nid(pfn, nid))
                continue;
            if (!update_defer_init(pgdat, pfn, end_pfn,
                        &nr_initialised))
                break;
        }
```

### set_pageblock_migratetype

将所有的页最初都标记为可移动的.

```
        /*
         * Mark the block movable so that blocks are reserved for
         * movable at startup. This will force kernel allocations
         * to reserve their blocks rather than leaking throughout
         * the address space during boot when many long-lived
         * kernel allocations are made. Later some blocks near
         * the start are marked MIGRATE_RESERVE by
         * setup_zone_migrate_reserve()
         *
         * bitmap is created for zone's valid pfn range. but memmap
         * can be created for invalid pages (for alignment)
         * check here not to call set_pageblock_migratetype() against
         * pfn out of zone.
         */
        if (!(pfn & (pageblock_nr_pages - 1))) {
            struct page *page = pfn_to_page(pfn);

            __init_single_page(page, pfn, zone, nid);
            set_pageblock_migratetype(page, MIGRATE_MOVABLE);
        } else {
            __init_single_pfn(pfn, zone, nid);
        }
    }
}
```

https://github.com/novelinux/linux-4.x.y/tree/master/mm/page_alloc.c/set_pageblock_migratetype.md
