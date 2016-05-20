for_each_reserved_mem_region
========================================

path: include/linux/memblock.h
```
/**
 * for_each_reserved_mem_region - iterate over all reserved memblock areas
 * @i: u64 used as loop variable
 * @p_start: ptr to phys_addr_t for start address of the range, can be %NULL
 * @p_end: ptr to phys_addr_t for end address of the range, can be %NULL
 *
 * Walks over reserved areas of memblock. Available as soon as memblock
 * is initialized.
 */
#define for_each_reserved_mem_region(i, p_start, p_end)    \
    for (i = 0UL,                                          \
         __next_reserved_mem_region(&i, p_start, p_end);   \
         i != (u64)ULLONG_MAX;                             \
         __next_reserved_mem_region(&i, p_start, p_end))
```

__next_reserved_mem_region
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/mm/memblock.c/__next_reserved_mem_region.md
