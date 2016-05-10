memblock
========================================

path: mm/memblock.c
```
static struct memblock_region memblock_memory_init_regions[INIT_MEMBLOCK_REGIONS] __initdata_memblock;
static struct memblock_region memblock_reserved_init_regions[INIT_MEMBLOCK_REGIONS] __initdata_memblock;
#ifdef CONFIG_HAVE_MEMBLOCK_PHYS_MAP
static struct memblock_region memblock_physmem_init_regions[INIT_PHYSMEM_REGIONS] __initdata_memblock;
#endif
...
struct memblock memblock __initdata_memblock = {
    .memory.regions    = memblock_memory_init_regions,
    .memory.cnt        = 1,    /* empty dummy entry */
    .memory.max        = INIT_MEMBLOCK_REGIONS,

    .reserved.regions  = memblock_reserved_init_regions,
    .reserved.cnt      = 1,    /* empty dummy entry */
    .reserved.max      = INIT_MEMBLOCK_REGIONS,

#ifdef CONFIG_HAVE_MEMBLOCK_PHYS_MAP
    .physmem.regions   = memblock_physmem_init_regions,
    .physmem.cnt       = 1,    /* empty dummy entry */
    .physmem.max       = INIT_PHYSMEM_REGIONS,
#endif

    .bottom_up         = false,
    .current_limit     = MEMBLOCK_ALLOC_ANYWHERE,
};
```

struct memblock
----------------------------------------

https://github.com/leeminghao/doc-linux/tree/master/4.x.y/include/linux/memblock.h/struct_memblock.md

MEMBLOCK_ALLOC_ANYWHERE
----------------------------------------

https://github.com/leeminghao/doc-linux/tree/master/4.x.y/include/linux/memblock.h/MEMBLOCK_ALLOC_ANYWHERE.md
