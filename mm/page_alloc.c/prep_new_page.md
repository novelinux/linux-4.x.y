prep_new_page
========================================

prep_new_page对页进行几项检查，确保分配之后分配器处于理想状态。特别地，这意味着在现存的映射中
不能使用该页，也没有设置不正确的标志（如PG_locked或PG_buddy），因为这说明页处于使用中，不应该
放置在空闲列表上。但通常情况下，不应该发生错误，否则就意味着内核在其他地方出现了错误。该函数也
为各个新页设置下列默认标志：

path: mm/page_alloc.c
```
static int prep_new_page(struct page *page, unsigned int order, gfp_t gfp_flags,
                         int alloc_flags)
{
    int i;

    for (i = 0; i < (1 << order); i++) {
        struct page *p = page + i;
        if (unlikely(check_new_page(p)))
            return 1;
    }

    set_page_private(page, 0);
    set_page_refcounted(page);

    arch_alloc_page(page, order);
    kernel_map_pages(page, 1 << order, 1);
    kasan_alloc_pages(page, order);

    if (gfp_flags & __GFP_ZERO)
        for (i = 0; i < (1 << order); i++)
            clear_highpage(page + i);

    if (order && (gfp_flags & __GFP_COMP))
        prep_compound_page(page, order);

    set_page_owner(page, order, gfp_flags);

    /*
     * page is set pfmemalloc when ALLOC_NO_WATERMARKS was necessary to
     * allocate the page. The expectation is that the caller is taking
     * steps that will free more memory. The caller should avoid the page
     * being used for !PFMEMALLOC purposes.
     */
    if (alloc_flags & ALLOC_NO_WATERMARKS)
        set_page_pfmemalloc(page);
    else
        clear_page_pfmemalloc(page);

    return 0;
}
```