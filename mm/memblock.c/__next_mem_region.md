__next_mem_region
========================================

path: mm/memblock.c
```
/**
 * __next__mem_range - next function for for_each_free_mem_range() etc.
 * @idx: pointer to u64 loop variable
 * @nid: node selector, %NUMA_NO_NODE for all nodes
 * @flags: pick from blocks based on memory attributes
 * @type_a: pointer to memblock_type from where the range is taken
 * @type_b: pointer to memblock_type which excludes memory from being taken
 * @out_start: ptr to phys_addr_t for start address of the range, can be %NULL
 * @out_end: ptr to phys_addr_t for end address of the range, can be %NULL
 * @out_nid: ptr to int for nid of the range, can be %NULL
 *
 * Find the first area from *@idx which matches @nid, fill the out
 * parameters, and update *@idx for the next iteration.  The lower 32bit of
 * *@idx contains index into type_a and the upper 32bit indexes the
 * areas before each region in type_b.    For example, if type_b regions
 * look like the following,
 *
 *    0:[0-16), 1:[32-48), 2:[128-130)
 *
 * The upper 32bit indexes the following regions.
 *
 *    0:[0-0), 1:[16-32), 2:[48-128), 3:[130-MAX)
 *
 * As both region arrays are sorted, the function advances the two indices
 * in lockstep and returns each intersection.
 */
void __init_memblock __next_mem_range(u64 *idx, int nid, ulong flags,
                      struct memblock_type *type_a,
                      struct memblock_type *type_b,
                      phys_addr_t *out_start,
                      phys_addr_t *out_end, int *out_nid)
{
    int idx_a = *idx & 0xffffffff;
    int idx_b = *idx >> 32;

    if (WARN_ONCE(nid == MAX_NUMNODES,
    "Usage of MAX_NUMNODES is deprecated. Use NUMA_NO_NODE instead\n"))
        nid = NUMA_NO_NODE;

    for (; idx_a < type_a->cnt; idx_a++) {
        struct memblock_region *m = &type_a->regions[idx_a];

        phys_addr_t m_start = m->base;
        phys_addr_t m_end = m->base + m->size;
        int        m_nid = memblock_get_region_node(m);

        /* only memory regions are associated with nodes, check it */
        if (nid != NUMA_NO_NODE && nid != m_nid)
            continue;

        /* skip hotpluggable memory regions if needed */
        if (movable_node_is_enabled() && memblock_is_hotpluggable(m))
            continue;

        /* if we want mirror memory skip non-mirror memory regions */
        if ((flags & MEMBLOCK_MIRROR) && !memblock_is_mirror(m))
            continue;

        if (!type_b) {
            if (out_start)
                *out_start = m_start;
            if (out_end)
                *out_end = m_end;
            if (out_nid)
                *out_nid = m_nid;
            idx_a++;
            *idx = (u32)idx_a | (u64)idx_b << 32;
            return;
        }

        /* scan areas before each reservation */
        for (; idx_b < type_b->cnt + 1; idx_b++) {
            struct memblock_region *r;
            phys_addr_t r_start;
            phys_addr_t r_end;

            r = &type_b->regions[idx_b];
            r_start = idx_b ? r[-1].base + r[-1].size : 0;
            r_end = idx_b < type_b->cnt ?
                r->base : ULLONG_MAX;

            /*
             * if idx_b advanced past idx_a,
             * break out to advance idx_a
             */
            if (r_start >= m_end)
                break;
            /* if the two regions intersect, we're done */
            if (m_start < r_end) {
                if (out_start)
                    *out_start =
                        max(m_start, r_start);
                if (out_end)
                    *out_end = min(m_end, r_end);
                if (out_nid)
                    *out_nid = m_nid;
                /*
                 * The region which ends first is
                 * advanced for the next iteration.
                 */
                if (m_end <= r_end)
                    idx_a++;
                else
                    idx_b++;
                *idx = (u32)idx_a | (u64)idx_b << 32;
                return;
            }
        }
    }

    /* signal end of iteration */
    *idx = ULLONG_MAX;
}
```