free_area_init_core
========================================

path: mm/page_alloc.c
```
/*
 * Set up the zone data structures:
 *   - mark all pages reserved
 *   - mark all memory queues empty
 *   - clear the memory bitmaps
 *
 * NOTE: pgdat should get zeroed by caller.
 */
static void __paginginit free_area_init_core(struct pglist_data *pgdat)
{
    enum zone_type j;
    int nid = pgdat->node_id;
    unsigned long zone_start_pfn = pgdat->node_start_pfn;
    int ret;

    /* 初始化node_size_lock */
    pgdat_resize_init(pgdat);
#ifdef CONFIG_NUMA_BALANCING
    spin_lock_init(&pgdat->numabalancing_migrate_lock);
    pgdat->numabalancing_migrate_nr_pages = 0;
    pgdat->numabalancing_migrate_next_window = jiffies;
#endif
    /* 初始化页换出进程的等待队列 */
    init_waitqueue_head(&pgdat->kswapd_wait);
    init_waitqueue_head(&pgdat->pfmemalloc_wait);
    pgdat_page_ext_init(pgdat);
```

Initialize Zones
----------------------------------------

逐个取出结点中各个内存域进行初始化工作.

```
    for (j = 0; j < MAX_NR_ZONES; j++) {
        struct zone *zone = pgdat->node_zones + j;
        unsigned long size, realsize, freesize, memmap_pages;

        size = zone->spanned_pages;
        /* 内存域的真实长度，可通过跨越的页数减去空洞覆盖的页数而得到。这两个值是通过
         * 两个辅助函数计算的。其复杂性实质上取决于内存模型和所选定的配置选项，但所有
         * 变体最终都没有什么意外之处。
         */
        realsize = freesize = zone->present_pages;

        /*
         * Adjust freesize so that it accounts for how much memory
         * is used by this zone for memmap. This affects the watermark
         * and per-cpu initialisations
         */
        memmap_pages = calc_memmap_size(size, realsize);
        if (!is_highmem_idx(j)) {
            if (freesize >= memmap_pages) {
                freesize -= memmap_pages;
                if (memmap_pages)
                    printk(KERN_DEBUG
                           "  %s zone: %lu pages used for memmap\n",
                           zone_names[j], memmap_pages);
            } else
                printk(KERN_WARNING
                    "  %s zone: %lu pages exceeds freesize %lu\n",
                    zone_names[j], memmap_pages, freesize);
        }

        /* Account for reserved pages */
        if (j == 0 && freesize > dma_reserve) {
            freesize -= dma_reserve;
            printk(KERN_DEBUG "  %s zone: %lu pages reserved\n",
                    zone_names[0], dma_reserve);
        }

        /* 内核使用两个全局变量跟踪系统中的页数。nr_kernel_pages统计所有一致映射的页，
         * 而nr_all_pages还包括高端内存页在内。
         */
        if (!is_highmem_idx(j))
            nr_kernel_pages += freesize;
        /* Charge for highmem memmap if there are enough kernel pages */
        else if (nr_kernel_pages > memmap_pages * 2)
            nr_kernel_pages -= memmap_pages;
        nr_all_pages += freesize;
```

### 初始化zone结构表头

```
        /*
         * Set an approximate value for lowmem here, it will be adjusted
         * when the bootmem allocator frees pages into the buddy system.
         * And all highmem pages will be managed by the buddy system.
         */
        zone->managed_pages = is_highmem_idx(j) ? realsize : freesize;
#ifdef CONFIG_NUMA
        zone->node = nid;
        zone->min_unmapped_pages = (freesize*sysctl_min_unmapped_ratio)
                        / 100;
        zone->min_slab_pages = (freesize * sysctl_min_slab_ratio) / 100;
#endif
        zone->name = zone_names[j];
        spin_lock_init(&zone->lock);
        spin_lock_init(&zone->lru_lock);
        zone_seqlock_init(zone);
        zone->zone_pgdat = pgdat;
```

#### zone_pcp_init

zone_pcp_init负责初始化对应zone的CPU高速缓存.在这里仅仅将zone->pageset赋值为与CPU
相关变量boot_pageset.真正的初始化工作在__build_all_zonelists函数中进行.

```
        zone_pcp_init(zone);
```

https://github.com/novelinux/linux-4.x.y/tree/master/mm/page_alloc.c/zone_pcp_init.md

#### mod_zone_page_state

```
        /* For bootup, initialized properly in watermark setup */
        mod_zone_page_state(zone, NR_ALLOC_BATCH, zone->managed_pages);
```

#### set_pageblock_order

```
        lruvec_init(&zone->lruvec);
        if (!size)
            continue;

        set_pageblock_order();
```

https://github.com/novelinux/linux-4.x.y/tree/master/mm/page_alloc.c/set_pageblock_order.md

#### setup_usemap

```
        setup_usemap(pgdat, zone, zone_start_pfn, size);
```

https://github.com/novelinux/linux-4.x.y/tree/master/mm/page_alloc.c/setup_usemap.md

#### init_currently_empty_zone

初始化free_area列表，并将属于该内存域的所有page实例都设置为初始默认值。所有页属性起初都
设置为MIGRATE_MOVABLE。

```
        ret = init_currently_empty_zone(zone, zone_start_pfn,
                        size, MEMMAP_EARLY);
        BUG_ON(ret);
```

https://github.com/novelinux/linux-4.x.y/tree/master/mm/page_alloc.c/init_currently_empty_zone.md

#### memmap_init

```
        memmap_init(size, nid, j, zone_start_pfn);
        zone_start_pfn += size;
    }
}
```

https://github.com/novelinux/linux-4.x.y/tree/master/mm/page_alloc.c/memmap_init.md

build_all_zonelists
----------------------------------------

节点和管理区的关键数据已完成初始化，内核在后面为内存管理做得一个准备工作就是将所有节点的管理区
都链入到zonelist中，便于后面内存分配工作的进行.

https://github.com/novelinux/linux-4.x.y/tree/master/mm/page_alloc.c/build_all_zonelists.md
