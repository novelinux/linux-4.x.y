bootmem_init
========================================

memblock_allow_resize
----------------------------------------

path: arch/arm/mm/init.c
```
void __init bootmem_init(void)
{
    unsigned long min, max_low, max_high;

    memblock_allow_resize();
```

https://github.com/novelinux/linux-4.x.y/tree/master/mm/memblock.c/memblock_allow_resize.md

find_limits
----------------------------------------

```
    max_low = max_high = 0;

    find_limits(&min, &max_low, &max_high);
```

https://github.com/novelinux/linux-4.x.y/tree/master/arch/arm/mm/init.c/find_limits.md

arm_memory_present
----------------------------------------

```
    /*
     * Sparsemem tries to allocate bootmem in memory_present(),
     * so must be done after the fixed reservations
     */
    arm_memory_present();
```

sparse_init
----------------------------------------

```
    /*
     * sparse_init() needs the bootmem allocator up and running.
     */
    sparse_init();
```

zone_sizes_init
----------------------------------------

```
    /*
     * Now free the memory - free_area_init_node needs
     * the sparse mem_map arrays initialized by sparse_init()
     * for memmap_init_zone(), otherwise all PFNs are invalid.
     */
    zone_sizes_init(min, max_low, max_high);
```

https://github.com/novelinux/linux-4.x.y/tree/master/arch/arm/mm/init.c/zone_sizes_init.md

min_low_pfn vs max_low_pfn vs max_pfn
----------------------------------------

```
    /*
     * This doesn't seem to be used by the Linux memory manager any
     * more, but is used by ll_rw_block.  If we can get rid of it, we
     * also get rid of some of the stuff above as well.
     */
    min_low_pfn = min;
    max_low_pfn = max_low;
    max_pfn = max_high;
}
```

### aries

```
min=80200, max_low=afa00, max_high=fffff
```