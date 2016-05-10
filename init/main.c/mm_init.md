mm_init
========================================

path: init/main.c
```
/*
 * Set up kernel memory allocators
 */
static void __init mm_init(void)
{
    /*
     * page_ext requires contiguous pages,
     * bigger than MAX_ORDER unless SPARSEMEM.
     */
     page_ext_init_flatmem();
     mem_init();
     kmem_cache_init();
     percpu_init_late();
     pgtable_init();
     vmalloc_init();
     ioremap_huge_init();
}
```
