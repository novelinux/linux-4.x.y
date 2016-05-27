free_all_bootmem
========================================

Code Flow
----------------------------------------

```
free_all_bootmem
  |
  +-> reset_all_zones_managed_pages
  |
  +-> free_low_memory_core_early
      |
      +-> __free_memory_core
      |
      +-> __free_pages_memory
      |
      +->  __free_pages_bootmem
      |
      +-> __free_pages_boot_core
      |
      +-> __free_pages
```

Arguments
----------------------------------------

path: mm/nobootmem.c
```
/**
 * free_all_bootmem - release free pages to the buddy allocator
 *
 * Returns the number of pages actually released.
 */
unsigned long __init free_all_bootmem(void)
{
    unsigned long pages;
```

reset_all_zones_managed_pages
----------------------------------------

```
    reset_all_zones_managed_pages();
```

https://github.com/novelinux/linux-4.x.y/tree/master/mm/nobootmem.c/reset_all_zones_managed_pages.md

free_low_memory_core_early
----------------------------------------

```
    /*
     * We need to use NUMA_NO_NODE instead of NODE_DATA(0)->node_id
     *  because in some case like Node0 doesn't have RAM installed
     *  low ram will be on Node1
     */
    pages = free_low_memory_core_early();
    totalram_pages += pages;

    return pages;
}
```

https://github.com/novelinux/linux-4.x.y/tree/master/mm/nobootmem.c/free_low_memory_core_early.md
