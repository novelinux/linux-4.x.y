__get_free_pages
========================================

path: mm/page_alloc.c
```
/*
 * Common helper functions.
 */
unsigned long __get_free_pages(gfp_t gfp_mask, unsigned int order)
{
    struct page *page;

    /*
     * __get_free_pages() returns a 32-bit address, which cannot represent
     * a highmem page
     */
    VM_BUG_ON((gfp_mask & __GFP_HIGHMEM) != 0);

    page = alloc_pages(gfp_mask, order);
    if (!page)
        return 0;
    return (unsigned long) page_address(page);
}
EXPORT_SYMBOL(__get_free_pages);
```

alloc_pages
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/gfp.h/alloc_pages.md