devicemaps_init
========================================

```
[    0.000000]     vector  : 0xffff0000 - 0xffff1000   (   4 kB)
[    0.000000]     vector  : 0xffff1000 - 0xffff2000   (   4 kB)
```

early_trap_init
----------------------------------------

为vectors分配两个page的物理内存.

path: arch/arm/mm/mmu.c
```
/*
 * Set up the device mappings.  Since we clear out the page tables for all
 * mappings above VMALLOC_START, we will remove any debug device mappings.
 * This means you have to be careful how you debug this function, or any
 * called function.  This means you can't use any function or debugging
 * method which may touch any device, otherwise the kernel _will_ crash.
 */
static void __init devicemaps_init(const struct machine_desc *mdesc)
{
    struct map_desc map;
    unsigned long addr;
    void *vectors;

    /*
     * Allocate the vector page early.
     */
    vectors = early_alloc(PAGE_SIZE * 2);

    early_trap_init(vectors);
```

map
----------------------------------------

```
    for (addr = VMALLOC_START; addr; addr += PMD_SIZE)
        pmd_clear(pmd_off_k(addr));

    /*
     * Map the kernel if it is XIP.
     * It is always first in the modulearea.
     */
#ifdef CONFIG_XIP_KERNEL
    map.pfn = __phys_to_pfn(CONFIG_XIP_PHYS_ADDR & SECTION_MASK);
    map.virtual = MODULES_VADDR;
    map.length = ((unsigned long)_etext - map.virtual + ~SECTION_MASK) & SECTION_MASK;
    map.type = MT_ROM;
    create_mapping(&map);
#endif

    /*
     * Map the cache flushing regions.
     */
#ifdef FLUSH_BASE
    map.pfn = __phys_to_pfn(FLUSH_BASE_PHYS);
    map.virtual = FLUSH_BASE;
    map.length = SZ_1M;
    map.type = MT_CACHECLEAN;
    create_mapping(&map);
#endif
#ifdef FLUSH_BASE_MINICACHE
    map.pfn = __phys_to_pfn(FLUSH_BASE_PHYS + SZ_1M);
    map.virtual = FLUSH_BASE_MINICACHE;
    map.length = SZ_1M;
    map.type = MT_MINICLEAN;
    create_mapping(&map);
#endif

    /*
     * Create a mapping for the machine vectors at the high-vectors
     * location (0xffff0000).  If we aren't using high-vectors, also
     * create a mapping at the low-vectors virtual address.
     */
     // vector: 0xffff0000 - 0xffff1000
    map.pfn = __phys_to_pfn(virt_to_phys(vectors));
    map.virtual = 0xffff0000;
    map.length = PAGE_SIZE;
#ifdef CONFIG_KUSER_HELPERS
    map.type = MT_HIGH_VECTORS;
#else
    map.type = MT_LOW_VECTORS;
#endif
    create_mapping(&map);

    if (!vectors_high()) {
        map.virtual = 0;
        map.length = PAGE_SIZE * 2;
        map.type = MT_LOW_VECTORS;
        create_mapping(&map);
    }

    /* Now create a kernel read-only mapping */
    // 0xffff1000 - 0xffff2000
    map.pfn += 1;
    map.virtual = 0xffff0000 + PAGE_SIZE;
    map.length = PAGE_SIZE;
    map.type = MT_LOW_VECTORS;
    create_mapping(&map);

    /*
     * Ask the machine support to map in the statically mapped devices.
     */
    if (mdesc->map_io)
        mdesc->map_io();
    else
        debug_ll_io_init();
    fill_pmd_gaps();

    /* Reserve fixed i/o space in VMALLOC region */
    pci_reserve_io();

    /*
     * Finally flush the caches and tlb to ensure that we're in a
     * consistent state wrt the writebuffer.  This also ensures that
     * any write-allocated cache lines in the vector page are written
     * back.  After this point, we can start to touch devices again.
     */
    local_flush_tlb_all();
    flush_cache_all();
}
```

### aries

```
CONFIG_KUSER_HELPERS=y
```