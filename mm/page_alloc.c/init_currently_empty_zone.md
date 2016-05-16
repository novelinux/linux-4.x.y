init_currently_empty_zone
========================================

path: mm/page_alloc.c
```
int __meminit init_currently_empty_zone(struct zone *zone,
                    unsigned long zone_start_pfn,
                    unsigned long size,
                    enum memmap_context context)
{
    struct pglist_data *pgdat = zone->zone_pgdat;
    int ret;
    ret = zone_wait_table_init(zone, size);
    if (ret)
        return ret;
    pgdat->nr_zones = zone_idx(zone) + 1;

    zone->zone_start_pfn = zone_start_pfn;

    mminit_dprintk(MMINIT_TRACE, "memmap_init",
            "Initialising map node %d zone %lu pfns %lu -> %lu\n",
            pgdat->node_id,
            (unsigned long)zone_idx(zone),
            zone_start_pfn, (zone_start_pfn + size));

    zone_init_free_lists(zone);

    return 0;
}
```

### aries

```
[    0.000000] mminit::memmap_init Initialising map node 0 zone 0 pfns 524800 -> 719360
[    0.000000] mminit::memmap_init Initialising map node 0 zone 1 pfns 719360 -> 1048575
```

zone_init_free_lists
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/mm/page_alloc.c/zone_init_free_lists.md
