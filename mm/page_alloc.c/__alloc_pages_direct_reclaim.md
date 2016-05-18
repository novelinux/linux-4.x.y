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
```

__perform_reclaim
----------------------------------------

```
    *did_some_progress = __perform_reclaim(gfp_mask, order, ac);
    if (unlikely(!(*did_some_progress)))
        return NULL;

    /* After successful reclaim, reconsider all zones for allocation */
    if (IS_ENABLED(CONFIG_NUMA))
        zlc_clear_zones_full(ac->zonelist);
```

https://github.com/novelinux/linux-4.x.y/tree/master/mm/page_alloc.c/__perform_reclaim.md

retry
----------------------------------------

接下来，如果__perform_reclaim函数中的try_to_free_pages释放了一些页，那么内核再次调用
get_page_from_freelist尝试分配内存.

```
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