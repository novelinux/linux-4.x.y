for_each_mem_range
========================================

path: include/linux/memblock.h
```
/**
 * for_each_mem_range - iterate through memblock areas from type_a and not
 * included in type_b. Or just type_a if type_b is NULL.
 * @i: u64 used as loop variable
 * @type_a: ptr to memblock_type to iterate
 * @type_b: ptr to memblock_type which excludes from the iteration
 * @nid: node selector, %NUMA_NO_NODE for all nodes
 * @flags: pick from blocks based on memory attributes
 * @p_start: ptr to phys_addr_t for start address of the range, can be %NULL
 * @p_end: ptr to phys_addr_t for end address of the range, can be %NULL
 * @p_nid: ptr to int for nid of the range, can be %NULL
 */
#define for_each_mem_range(i, type_a, type_b, nid, flags,        \
               p_start, p_end, p_nid)                            \
    for (i = 0, __next_mem_range(&i, nid, flags, type_a, type_b, \
                     p_start, p_end, p_nid);                     \
         i != (u64)ULLONG_MAX;                                   \
         __next_mem_range(&i, nid, flags, type_a, type_b,        \
                  p_start, p_end, p_nid))
```

__next_mem_range
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/mm/memblock.c/__next_mem_region.md
