for_each_free_mem_range
========================================

path: include/linux/memblock.h
```
/**
 * for_each_free_mem_range - iterate through free memblock areas
 * @i: u64 used as loop variable
 * @nid: node selector, %NUMA_NO_NODE for all nodes
 * @p_start: ptr to phys_addr_t for start address of the range, can be %NULL
 * @p_end: ptr to phys_addr_t for end address of the range, can be %NULL
 * @p_nid: ptr to int for nid of the range, can be %NULL
 * @flags: pick from blocks based on memory attributes
 *
 * Walks over free (memory && !reserved) areas of memblock.  Available as
 * soon as memblock is initialized.
 */
#define for_each_free_mem_range(i, nid, flags, p_start, p_end, p_nid)    \
    for_each_mem_range(i, &memblock.memory, &memblock.reserved,          \
               nid, flags, p_start, p_end, p_nid)
```

for_each_mem_range
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/memblock.h/for_each_mem_range.md