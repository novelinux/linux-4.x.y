reserve_bootmem_region
========================================

path: mm/page_alloc.c
```
/*
 * Initialised pages do not have PageReserved set. This function is
 * called for each range allocated by the bootmem allocator and
 * marks the pages PageReserved. The remaining valid pages are later
 * sent to the buddy page allocator.
 */
void __meminit reserve_bootmem_region(unsigned long start, unsigned long end)
{
    unsigned long start_pfn = PFN_DOWN(start);
    unsigned long end_pfn = PFN_UP(end);

    for (; start_pfn < end_pfn; start_pfn++) {
        if (pfn_valid(start_pfn)) {
            struct page *page = pfn_to_page(start_pfn);

            init_reserved_page(start_pfn);
            SetPageReserved(page);
        }
    }
}
```