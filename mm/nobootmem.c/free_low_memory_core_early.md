free_low_memory_core_early
========================================

Arguments
----------------------------------------

path: mm/nobootmem.c
```
static unsigned long __init free_low_memory_core_early(void)
{
    unsigned long count = 0;
    phys_addr_t start, end;
    u64 i;

    memblock_clear_hotplug(0, -1);
```

reserve_bootmem_region
----------------------------------------

```
    for_each_reserved_mem_region(i, &start, &end)
        reserve_bootmem_region(start, end);
```

### for_each_reserved_mem_region

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/memblock.h/for_each_reserved_mem_region.md

### reserve_bootmem_region

https://github.com/novelinux/linux-4.x.y/tree/master/mm/page_alloc.c/reserve_bootmem_region.md

__free_memory_core
----------------------------------------

```
    for_each_free_mem_range(i, NUMA_NO_NODE, MEMBLOCK_NONE, &start, &end,
                NULL)
        count += __free_memory_core(start, end);
```

### for_each_free_mem_range

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/memblock.h/for_each_free_mem_range.md

### __free_memory_core

https://github.com/novelinux/linux-4.x.y/tree/master/mm/nobootmem.c/__free_memory_core.md

### aries

```
start=80200 end=afa00
```

Return
----------------------------------------

```
#ifdef CONFIG_ARCH_DISCARD_MEMBLOCK
    {
        phys_addr_t size;

        /* Free memblock.reserved array if it was allocated */
        size = get_allocated_memblock_reserved_regions_info(&start);
        if (size)
            count += __free_memory_core(start, start + size);

        /* Free memblock.memory array if it was allocated */
        size = get_allocated_memblock_memory_regions_info(&start);
        if (size)
            count += __free_memory_core(start, start + size);
    }
#endif

    return count;
}
```