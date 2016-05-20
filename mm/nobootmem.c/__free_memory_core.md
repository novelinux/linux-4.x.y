__free_memory_core
========================================

path: mm/nobootmem.c
```
static unsigned long __init __free_memory_core(phys_addr_t start,
                 phys_addr_t end)
{
    unsigned long start_pfn = PFN_UP(start);
    unsigned long end_pfn = min_t(unsigned long,
                      PFN_DOWN(end), max_low_pfn);

    if (start_pfn > end_pfn)
        return 0;

    __free_pages_memory(start_pfn, end_pfn);

    return end_pfn - start_pfn;
}
```

__free_pages_memory
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/mm/nobootmem.c/__free_pages_memory.md
