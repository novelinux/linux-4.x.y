free_block
========================================

path: mm/slab.c
```
/*
 * Caller needs to acquire correct kmem_cache_node's list_lock
 * @list: List of detached free slabs should be freed by caller
 */
static void free_block(struct kmem_cache *cachep, void **objpp,
            int nr_objects, int node, struct list_head *list)
{
    int i;
    struct kmem_cache_node *n = get_node(cachep, node);

    for (i = 0; i < nr_objects; i++) {
        void *objp;
        struct page *page;

        clear_obj_pfmemalloc(&objpp[i]);
        objp = objpp[i];

        page = virt_to_head_page(objp);
        list_del(&page->lru);
        check_spinlock_acquired_node(cachep, node);
        slab_put_obj(cachep, page, objp, node);
        STATS_DEC_ACTIVE(cachep);
        n->free_objects++;

        /* fixup slab chains */
        if (page->active == 0) {
            if (n->free_objects > n->free_limit) {
                n->free_objects -= cachep->num;
                list_add_tail(&page->lru, list);
            } else {
                list_add(&page->lru, &n->slabs_free);
            }
        } else {
            /* Unconditionally move a slab to the end of the
             * partial list on free - maximum time for the
             * other objects to be freed, too.
             */
            list_add_tail(&page->lru, &n->slabs_partial);
        }
    }
}
```