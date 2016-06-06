obj_to_index
========================================

path: mm/slab.c
```
/*
 * We want to avoid an expensive divide : (offset / cache->size)
 *   Using the fact that size is a constant for a particular cache,
 *   we can replace (offset / cache->size) by
 *   reciprocal_divide(offset, cache->reciprocal_buffer_size)
 */
static inline unsigned int obj_to_index(const struct kmem_cache *cache,
                    const struct page *page, void *obj)
{
    u32 offset = (obj - page->s_mem);
    return reciprocal_divide(offset, cache->reciprocal_buffer_size);
}
```
