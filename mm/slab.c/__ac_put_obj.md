__ac_put_obj
========================================

path: mm/slab.c
```
static noinline void *__ac_put_obj(struct kmem_cache *cachep,
            struct array_cache *ac, void *objp)
{
    if (unlikely(pfmemalloc_active)) {
        /* Some pfmemalloc slabs exist, check if this is one */
        struct page *page = virt_to_head_page(objp);
        if (PageSlabPfmemalloc(page))
            set_obj_pfmemalloc(&objp);
    }

    return objp;
}
```