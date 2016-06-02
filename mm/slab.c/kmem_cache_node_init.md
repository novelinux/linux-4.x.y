kmem_cache_node_init
========================================

path: mm/slab.c
```
static void kmem_cache_node_init(struct kmem_cache_node *parent)
{
    INIT_LIST_HEAD(&parent->slabs_full);
    INIT_LIST_HEAD(&parent->slabs_partial);
    INIT_LIST_HEAD(&parent->slabs_free);
    parent->shared = NULL;
    parent->alien = NULL;
    parent->colour_next = 0;
    spin_lock_init(&parent->list_lock);
    parent->free_objects = 0;
    parent->free_touched = 0;
}
```