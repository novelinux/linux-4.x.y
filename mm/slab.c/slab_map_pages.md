slab_map_pages
========================================

path: mm/slab.c
```
/*
 * Map pages beginning at addr to the given cache and slab. This is required
 * for the slab allocator to be able to lookup the cache and slab of a
 * virtual address for kfree, ksize, and slab debugging.
 */
static void slab_map_pages(struct kmem_cache *cache, struct page *page,
               void *freelist)
{
    page->slab_cache = cache;
    page->freelist = freelist;
}
```