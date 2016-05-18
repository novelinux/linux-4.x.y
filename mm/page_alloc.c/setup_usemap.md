setup_usemap
========================================

path: mm/page_alloc.c
```
#ifndef CONFIG_SPARSEMEM
/*
 * Calculate the size of the zone->blockflags rounded to an unsigned long
 * Start by making sure zonesize is a multiple of pageblock_order by rounding
 * up. Then use 1 NR_PAGEBLOCK_BITS worth of bits per pageblock, finally
 * round what is now in bits to nearest long in bits, then return it in
 * bytes.
 */
static unsigned long __init usemap_size(unsigned long zone_start_pfn, unsigned long zonesize)
{
    unsigned long usemapsize;

    zonesize += zone_start_pfn & (pageblock_nr_pages-1);
    usemapsize = roundup(zonesize, pageblock_nr_pages);
    usemapsize = usemapsize >> pageblock_order;
    usemapsize *= NR_PAGEBLOCK_BITS;
    usemapsize = roundup(usemapsize, 8 * sizeof(unsigned long));

    return usemapsize / 8;
}

static void __init setup_usemap(struct pglist_data *pgdat,
                struct zone *zone,
                unsigned long zone_start_pfn,
                unsigned long zonesize)
{
    unsigned long usemapsize = usemap_size(zone_start_pfn, zonesize);
    zone->pageblock_flags = NULL;
    if (usemapsize)
        zone->pageblock_flags =
            memblock_virt_alloc_node_nopanic(usemapsize,
                             pgdat->node_id);
}
#else
static inline void setup_usemap(struct pglist_data *pgdat, struct zone *zone,
                unsigned long zone_start_pfn, unsigned long zonesize) {}
#endif /* CONFIG_SPARSEMEM */
```
