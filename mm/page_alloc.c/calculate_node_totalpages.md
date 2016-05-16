calculate_node_totalpages
========================================

calculate_node_totalpages首先累计各个内存域的页数，计算结点中页的总数。calculate_zone_totalpages
还考虑了内存域中的空洞。在系统启动时，会输出一段简短的消息，指明各个结点的页数。

path: mm/page_alloc.c
```
static void __meminit calculate_node_totalpages(struct pglist_data *pgdat,
                        unsigned long node_start_pfn,
                        unsigned long node_end_pfn,
                        unsigned long *zones_size,
                        unsigned long *zholes_size)
{
    unsigned long realtotalpages = 0, totalpages = 0;
    enum zone_type i;

    for (i = 0; i < MAX_NR_ZONES; i++) {
        struct zone *zone = pgdat->node_zones + i;
        unsigned long size, real_size;

        size = zone_spanned_pages_in_node(pgdat->node_id, i,
                          node_start_pfn,
                          node_end_pfn,
                          zones_size);
        real_size = size - zone_absent_pages_in_node(pgdat->node_id, i,
                          node_start_pfn, node_end_pfn,
                          zholes_size);
        zone->spanned_pages = size;
        zone->present_pages = real_size;

        totalpages += size;
        realtotalpages += real_size;
    }

    pgdat->node_spanned_pages = totalpages;
    pgdat->node_present_pages = realtotalpages;
    printk(KERN_DEBUG "On node %d totalpages: %lu\n", pgdat->node_id,
                            realtotalpages);
}
```