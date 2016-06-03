index_to_obj
========================================

path: mm/slab.c
```
static inline void *index_to_obj(struct kmem_cache *cache, struct page *page,
                 unsigned int idx)
{
    return page->s_mem + cache->size * idx;
}
```