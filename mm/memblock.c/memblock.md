memblock
========================================

path: mm/memblock.c
```
// 每一个数组包含128个内存区域
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
    // 当前Memblock的大小限制是0xffffffffffffffff
    .current_limit     = MEMBLOCK_ALLOC_ANYWHERE,
};
```

struct memblock
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/memblock.h/struct_memblock.md

__initdata_memblock
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/memblock.h/__initdata_memblock.md
