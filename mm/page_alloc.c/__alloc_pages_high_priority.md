__alloc_pages_high_priority
========================================

path: mm/page_alloc.c
```
/*
 * This is called in the allocator slow-path if the allocation request is of
 * sufficient urgency to ignore watermarks and take other desperate measures
 */
static inline struct page *
__alloc_pages_high_priority(gfp_t gfp_mask, unsigned int order,
                const struct alloc_context *ac)
{
    struct page *page;

    do {
        page = get_page_from_freelist(gfp_mask, order,
                        ALLOC_NO_WATERMARKS, ac);

        if (!page && gfp_mask & __GFP_NOFAIL)
            wait_iff_congested(ac->preferred_zone, BLK_RW_ASYNC,
                                    HZ/50);
    } while (!page && (gfp_mask & __GFP_NOFAIL));

    return page;
}
```