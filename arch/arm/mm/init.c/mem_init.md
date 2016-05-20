mem_init
========================================

Arguments
----------------------------------------

path: arch/arm/mm/init.c
```
/*
 * mem_init() marks the free areas in the mem_map and tells us how much
 * memory is free.  This is done after various parts of the system have
 * claimed their memory after the kernel image.
 */
void __init mem_init(void)
{
#ifdef CONFIG_HAVE_TCM
    /* These pointers are filled in on TCM detection */
    extern u32 dtcm_end;
    extern u32 itcm_end;
#endif
```

set_max_mapnr
----------------------------------------

```
    set_max_mapnr(pfn_to_page(max_pfn) - mem_map);
```

free_unused_memmap
----------------------------------------

```
    /* this will put all unused low memory onto the freelists */
    free_unused_memmap();
```

free_all_bootmem
----------------------------------------

```
    free_all_bootmem();
```

https://github.com/novelinux/linux-4.x.y/blob/master/mm/nobootmem.c/free_all_bootmem.md

free_highpages
----------------------------------------

```
#ifdef CONFIG_SA1111
    /* now that our DMA memory is actually so designated, we can free it */
    free_reserved_area(__va(PHYS_OFFSET), swapper_pg_dir, -1, NULL);
#endif

    free_highpages();
```

https://github.com/novelinux/linux-4.x.y/tree/master/arch/arm/mm/init.c/free_highpages.md

Print info
----------------------------------------

```
    mem_init_print_info(NULL);

#define MLK(b, t) b, t, ((t) - (b)) >> 10
#define MLM(b, t) b, t, ((t) - (b)) >> 20
#define MLK_ROUNDUP(b, t) b, t, DIV_ROUND_UP(((t) - (b)), SZ_1K)

    pr_notice("Virtual kernel memory layout:\n"
            "    vector  : 0x%08lx - 0x%08lx   (%4ld kB)\n"
#ifdef CONFIG_HAVE_TCM
            "    DTCM    : 0x%08lx - 0x%08lx   (%4ld kB)\n"
            "    ITCM    : 0x%08lx - 0x%08lx   (%4ld kB)\n"
#endif
            "    fixmap  : 0x%08lx - 0x%08lx   (%4ld kB)\n"
            "    vmalloc : 0x%08lx - 0x%08lx   (%4ld MB)\n"
            "    lowmem  : 0x%08lx - 0x%08lx   (%4ld MB)\n"
#ifdef CONFIG_HIGHMEM
            "    pkmap   : 0x%08lx - 0x%08lx   (%4ld MB)\n"
#endif
#ifdef CONFIG_MODULES
            "    modules : 0x%08lx - 0x%08lx   (%4ld MB)\n"
#endif
            "      .text : 0x%p" " - 0x%p" "   (%4td kB)\n"
            "      .init : 0x%p" " - 0x%p" "   (%4td kB)\n"
            "      .data : 0x%p" " - 0x%p" "   (%4td kB)\n"
            "       .bss : 0x%p" " - 0x%p" "   (%4td kB)\n",

            MLK(UL(CONFIG_VECTORS_BASE), UL(CONFIG_VECTORS_BASE) +
                (PAGE_SIZE)),
#ifdef CONFIG_HAVE_TCM
            MLK(DTCM_OFFSET, (unsigned long) dtcm_end),
            MLK(ITCM_OFFSET, (unsigned long) itcm_end),
#endif
            MLK(FIXADDR_START, FIXADDR_END),
            MLM(VMALLOC_START, VMALLOC_END),
            MLM(PAGE_OFFSET, (unsigned long)high_memory),
#ifdef CONFIG_HIGHMEM
            MLM(PKMAP_BASE, (PKMAP_BASE) + (LAST_PKMAP) *
                (PAGE_SIZE)),
#endif
#ifdef CONFIG_MODULES
            MLM(MODULES_VADDR, MODULES_END),
#endif

            MLK_ROUNDUP(_text, _etext),
            MLK_ROUNDUP(__init_begin, __init_end),
            MLK_ROUNDUP(_sdata, _edata),
            MLK_ROUNDUP(__bss_start, __bss_stop));

#undef MLK
#undef MLM
#undef MLK_ROUNDUP

    /*
     * Check boundaries twice: Some fundamental inconsistencies can
     * be detected at build time already.
     */
#ifdef CONFIG_MMU
    BUILD_BUG_ON(TASK_SIZE                > MODULES_VADDR);
    BUG_ON(TASK_SIZE                 > MODULES_VADDR);
#endif

#ifdef CONFIG_HIGHMEM
    BUILD_BUG_ON(PKMAP_BASE + LAST_PKMAP * PAGE_SIZE > PAGE_OFFSET);
    BUG_ON(PKMAP_BASE + LAST_PKMAP * PAGE_SIZE    > PAGE_OFFSET);
#endif

    if (PAGE_SIZE >= 16384 && get_num_physpages() <= 128) {
        extern int sysctl_overcommit_memory;
        /*
         * On a machine this small we won't get
         * anywhere without overcommit, so turn
         * it on by default.
         */
        sysctl_overcommit_memory = OVERCOMMIT_ALWAYS;
    }
}
```

Virtual kernel memory layout
----------------------------------------

https://github.com/novelinux/linux-4.x.y/blob/master/arch/arm/mm/README.md
