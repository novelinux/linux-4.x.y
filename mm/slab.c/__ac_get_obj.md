__ac_get_obj
========================================

path: mm/slab.c
```
static void *__ac_get_obj(struct kmem_cache *cachep, struct array_cache *ac,
                        gfp_t flags, bool force_refill)
{
    int i;
    void *objp = ac->entry[--ac->avail];

    /* Ensure the caller is allowed to use objects from PFMEMALLOC slab */
    if (unlikely(is_obj_pfmemalloc(objp))) {
        struct kmem_cache_node *n;

        if (gfp_pfmemalloc_allowed(flags)) {
            clear_obj_pfmemalloc(&objp);
            return objp;
        }

        /* The caller cannot use PFMEMALLOC objects, find another one */
        for (i = 0; i < ac->avail; i++) {
            /* If a !PFMEMALLOC object is found, swap them */
            if (!is_obj_pfmemalloc(ac->entry[i])) {
                objp = ac->entry[i];
                ac->entry[i] = ac->entry[ac->avail];
                ac->entry[ac->avail] = objp;
                return objp;
            }
        }

        /*
         * If there are empty slabs on the slabs_free list and we are
         * being forced to refill the cache, mark this one !pfmemalloc.
         */
        n = get_node(cachep, numa_mem_id());
        if (!list_empty(&n->slabs_free) && force_refill) {
            struct page *page = virt_to_head_page(objp);
            ClearPageSlabPfmemalloc(page);
            clear_obj_pfmemalloc(&objp);
            recheck_pfmemalloc_active(cachep, ac);
            return objp;
        }

        /* No !PFMEMALLOC objects available */
        ac->avail++;
        objp = NULL;
    }

    return objp;
}
```