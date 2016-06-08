kmem_getpages
========================================

Arguments
----------------------------------------

path: mm/slab.c
```
/*
 * Interface to system's page allocator. No need to hold the
 * kmem_cache_node ->list_lock.
 *
 * If we requested dmaable memory, we will get it. Even if we
 * did not request dmaable memory, we might get it, but that
 * would be relatively rare and ignorable.
 */
static struct page *kmem_getpages(struct kmem_cache *cachep, gfp_t flags,
                                int nodeid)
{
    struct page *page;
    int nr_pages;

    flags |= cachep->allocflags;
    if (cachep->flags & SLAB_RECLAIM_ACCOUNT)
        flags |= __GFP_RECLAIMABLE;

    if (memcg_charge_slab(cachep, flags, cachep->gfporder))
        return NULL;
```

__alloc_pages_node
----------------------------------------

```
    page = __alloc_pages_node(nodeid, flags | __GFP_NOTRACK, cachep->gfporder);
    if (!page) {
        memcg_uncharge_slab(cachep, cachep->gfporder);
        slab_out_of_memory(cachep, flags, nodeid);
        return NULL;
    }

    /* Record if ALLOC_NO_WATERMARKS was set when allocating the slab */
    if (page_is_pfmemalloc(page))
        pfmemalloc_active = true;

    nr_pages = (1 << cachep->gfporder);
    if (cachep->flags & SLAB_RECLAIM_ACCOUNT)
        add_zone_page_state(page_zone(page),
            NR_SLAB_RECLAIMABLE, nr_pages);
    else
        add_zone_page_state(page_zone(page),
            NR_SLAB_UNRECLAIMABLE, nr_pages);
    __SetPageSlab(page);
    if (page_is_pfmemalloc(page))
        SetPageSlabPfmemalloc(page);

    if (kmemcheck_enabled && !(cachep->flags & SLAB_NOTRACK)) {
        kmemcheck_alloc_shadow(page, cachep->gfporder, flags, nodeid);

        if (cachep->ctor)
            kmemcheck_mark_uninitialized_pages(page, nr_pages);
        else
            kmemcheck_mark_unallocated_pages(page, nr_pages);
    }

    return page;
}
```

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/gfp.h/__alloc_pages_node.md