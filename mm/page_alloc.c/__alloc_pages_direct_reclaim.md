__alloc_pages_direct_reclaim
========================================

path: mm/page_alloc.c
```
/* The really slow allocator path where we enter direct reclaim */
static inline struct page *
__alloc_pages_direct_reclaim(gfp_t gfp_mask, unsigned int order,
        int alloc_flags, const struct alloc_context *ac,
        unsigned long *did_some_progress)
{
    struct page *page = NULL;
    bool drained = false;

    *did_some_progress = __perform_reclaim(gfp_mask, order, ac);
    if (unlikely(!(*did_some_progress)))
        return NULL;

    /* After successful reclaim, reconsider all zones for allocation */
    if (IS_ENABLED(CONFIG_NUMA))
        zlc_clear_zones_full(ac->zonelist);

retry:
    page = get_page_from_freelist(gfp_mask, order,
                    alloc_flags & ~ALLOC_NO_WATERMARKS, ac);

    /*
     * If an allocation failed after direct reclaim, it could be because
     * pages are pinned on the per-cpu lists. Drain them and try again
     */
    if (!page && !drained) {
        drain_all_pages(NULL);
        drained = true;
        goto retry;
    }

    return page;
}
```