alloc_slabmgmt
========================================

path: mm/slab.c
```
/*
 * Get the memory for a slab management obj.
 *
 * For a slab cache when the slab descriptor is off-slab, the
 * slab descriptor can't come from the same cache which is being created,
 * Because if it is the case, that means we defer the creation of
 * the kmalloc_{dma,}_cache of size sizeof(slab descriptor) to this point.
 * And we eventually call down to __kmem_cache_create(), which
 * in turn looks up in the kmalloc_{dma,}_caches for the disired-size one.
 * This is a "chicken-and-egg" problem.
 *
 * So the off-slab slab descriptor shall come from the kmalloc_{dma,}_caches,
 * which are all initialized during kmem_cache_init().
 */
static void *alloc_slabmgmt(struct kmem_cache *cachep,
                   struct page *page, int colour_off,
                   gfp_t local_flags, int nodeid)
{
    void *freelist;
    void *addr = page_address(page);

    if (OFF_SLAB(cachep)) {
        /* Slab management obj is off-slab. */
        freelist = kmem_cache_alloc_node(cachep->freelist_cache,
                          local_flags, nodeid);
        if (!freelist)
            return NULL;
    } else {
        freelist = addr + colour_off;
        colour_off += cachep->freelist_size;
    }
    page->active = 0;
    page->s_mem = addr + colour_off;
    return freelist;
}
```