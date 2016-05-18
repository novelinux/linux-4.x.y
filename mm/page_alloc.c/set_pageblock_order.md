set_pageblock_order
========================================

path: mm/page_alloc.c
```
#ifdef CONFIG_HUGETLB_PAGE_SIZE_VARIABLE

/* Initialise the number of pages represented by NR_PAGEBLOCK_BITS */
void __paginginit set_pageblock_order(void)
{
    unsigned int order;

    /* Check that pageblock_nr_pages has not already been setup */
    if (pageblock_order)
        return;

    if (HPAGE_SHIFT > PAGE_SHIFT)
        order = HUGETLB_PAGE_ORDER;
    else
        order = MAX_ORDER - 1;

    /*
     * Assume the largest contiguous order of interest is a huge page.
     * This value may be variable depending on boot parameters on IA64 and
     * powerpc.
     */
    pageblock_order = order;
}
#else /* CONFIG_HUGETLB_PAGE_SIZE_VARIABLE */

/*
 * When CONFIG_HUGETLB_PAGE_SIZE_VARIABLE is not set, set_pageblock_order()
 * is unused as pageblock_order is set at compile-time. See
 * include/linux/pageblock-flags.h for the values of pageblock_order based on
 * the kernel config
 */
void __paginginit set_pageblock_order(void)
{
}

#endif /* CONFIG_HUGETLB_PAGE_SIZE_VARIABLE */

pageblock_order
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/pageblock-flags.h/pageblock_order.md