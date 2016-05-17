__zone_watermark_ok
========================================

path: mm/page_alloc.c
```
/*
 * Return true if free pages are above 'mark'. This takes into account the order
 * of the allocation.
 */
static bool __zone_watermark_ok(struct zone *z, unsigned int order,
            unsigned long mark, int classzone_idx, int alloc_flags,
            long free_pages)
{
    /* free_pages may go negative - that's OK */
    long min = mark;
    int o;
    long free_cma = 0;

    free_pages -= (1 << order) - 1;
    /* ALLOC_HIGH和ALLOC_HARDER标志之后（将最小值标记降低到当前值的一半或四分之一，
     * 使得分配过程努力或更加努力）
     */
    if (alloc_flags & ALLOC_HIGH)
        min -= min / 2;
    if (alloc_flags & ALLOC_HARDER)
        min -= min / 4;
#ifdef CONFIG_CMA
    /* If allocation can't use CMA areas don't use free CMA pages */
    if (!(alloc_flags & ALLOC_CMA))
        free_cma = zone_page_state(z, NR_FREE_CMA_PAGES);
#endif

    /* 该函数会检查空闲页的数目是否小于最小值与lowmem_reserve中指定的紧急分配值之和。
     * 如果不小于，则代码遍历所有小于当前阶的分配阶，从free_pages减去当前分配阶的
     * 所有空闲页（左移o位是必要的，因为nr_free记载的是当前分配阶的空闲页块数目）。
     * 同时，每升高一阶，所需空闲页的最小值折半。如果内核遍历所有的低端内存域之后，
     * 发现内存不足，则不进行内存分配。
     */
    if (free_pages - free_cma <= min + z->lowmem_reserve[classzone_idx])
        return false;
    for (o = 0; o < order; o++) {
        /* At the next order, this order's pages become unavailable */
        free_pages -= z->free_area[o].nr_free << o;

        /* Require fewer higher order pages to be free */
        min >>= 1;

        if (free_pages <= min)
            return false;
    }
    return true;
}
```

### aries

```
CONFIG_CMA=y
```