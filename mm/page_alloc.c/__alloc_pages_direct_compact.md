__alloc_pages_direct_compact
========================================

Arguments
----------------------------------------

path: mm/page_alloc.c
```
#ifdef CONFIG_COMPACTION
/* Try memory compaction for high-order allocations before reclaim */
static struct page *
__alloc_pages_direct_compact(gfp_t gfp_mask, unsigned int order,
        int alloc_flags, const struct alloc_context *ac,
        enum migrate_mode mode, int *contended_compaction,
        bool *deferred_compaction)
{
    unsigned long compact_result;
    struct page *page;

    if (!order)
        return NULL;
```

try_to_compact_pages
----------------------------------------

```
    current->flags |= PF_MEMALLOC;
    compact_result = try_to_compact_pages(gfp_mask, order, alloc_flags, ac,
                        mode, contended_compaction);
    current->flags &= ~PF_MEMALLOC;

    switch (compact_result) {
    case COMPACT_DEFERRED:
        *deferred_compaction = true;
        /* fall-through */
    case COMPACT_SKIPPED:
        return NULL;
    default:
        break;
    }

    /*
     * At least in one zone compaction wasn't deferred or skipped, so let's
     * count a compaction stall
     */
    count_vm_event(COMPACTSTALL);
```

get_page_from_freelist
----------------------------------------

```
    page = get_page_from_freelist(gfp_mask, order,
                    alloc_flags & ~ALLOC_NO_WATERMARKS, ac);

    if (page) {
        struct zone *zone = page_zone(page);

        zone->compact_blockskip_flush = false;
        compaction_defer_reset(zone, order, true);
        count_vm_event(COMPACTSUCCESS);
        return page;
    }

    /*
     * It's bad if compaction run occurs and fails. The most likely reason
     * is that pages exist, but not enough to satisfy watermarks.
     */
    count_vm_event(COMPACTFAIL);

    cond_resched();

    return NULL;
}
#else
static inline struct page *
__alloc_pages_direct_compact(gfp_t gfp_mask, unsigned int order,
        int alloc_flags, const struct alloc_context *ac,
        enum migrate_mode mode, int *contended_compaction,
        bool *deferred_compaction)
{
    return NULL;
}
#endif /* CONFIG_COMPACTION */
```

aires
----------------------------------------

```
# CONFIG_COMPACTION is not set
```

gemini
----------------------------------------

```
CONFIG_COMPACTION=y
```