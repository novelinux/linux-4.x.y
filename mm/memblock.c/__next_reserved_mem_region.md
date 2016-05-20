__next_reserved_mem_region
========================================

path: mm/memblock.c
```
/**
 * __next_reserved_mem_region - next function for for_each_reserved_region()
 * @idx: pointer to u64 loop variable
 * @out_start: ptr to phys_addr_t for start address of the region, can be %NULL
 * @out_end: ptr to phys_addr_t for end address of the region, can be %NULL
 *
 * Iterate over all reserved memory regions.
 */
void __init_memblock __next_reserved_mem_region(u64 *idx,
                       phys_addr_t *out_start,
                       phys_addr_t *out_end)
{
    struct memblock_type *type = &memblock.reserved;

    if (*idx >= 0 && *idx < type->cnt) {
        struct memblock_region *r = &type->regions[*idx];
        phys_addr_t base = r->base;
        phys_addr_t size = r->size;

        if (out_start)
            *out_start = base;
        if (out_end)
            *out_end = base + size - 1;

        *idx += 1;
        return;
    }

    /* signal end of iteration */
    *idx = ULLONG_MAX;
}
```
