free_area_high
========================================

path: arch/arm/mm/init.c
```
#ifdef CONFIG_HIGHMEM
static inline void free_area_high(unsigned long pfn, unsigned long end)
{
    for (; pfn < end; pfn++)
        free_highmem_page(pfn_to_page(pfn));
}
#endif
```