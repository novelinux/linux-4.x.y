free_highpages
========================================

path: arch/arm/mm/init.c
```
static void __init free_highpages(void)
{
#ifdef CONFIG_HIGHMEM
    unsigned long max_low = max_low_pfn;
    struct memblock_region *mem, *res;

    /* set highmem page free */
    for_each_memblock(memory, mem) {
        unsigned long start = memblock_region_memory_base_pfn(mem);
        unsigned long end = memblock_region_memory_end_pfn(mem);

        /* Ignore complete lowmem entries */
        if (end <= max_low)
            continue;

        /* Truncate partial highmem entries */
        if (start < max_low)
            start = max_low;

        /* Find and exclude any reserved regions */
        for_each_memblock(reserved, res) {
            unsigned long res_start, res_end;

            res_start = memblock_region_reserved_base_pfn(res);
            res_end = memblock_region_reserved_end_pfn(res);

            if (res_end < start)
                continue;
            if (res_start < start)
                res_start = start;
            if (res_start > end)
                res_start = end;
            if (res_end > end)
                res_end = end;
            if (res_start != start)
                free_area_high(start, res_start);
            start = res_end;
            if (start == end)
                break;
        }

        /* And now free anything which remains */
        if (start < end)
            free_area_high(start, end);
    }
#endif
}
```

free_area_high
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/arch/arm/mm/init.c/free_area_high.md
