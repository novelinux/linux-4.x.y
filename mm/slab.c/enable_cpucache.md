enable_cpucache
========================================

Code Flow
----------------------------------------

```
enable_cpucache
 |
 +-> do_tune_cpucache
     |
     +-> __do_tune_cpucache
         |
         +-> alloc_kmem_cache_cpus
         |
         +-> alloc_kmem_cache_node
             |
             +-> get_node
             |
             +-> kmalloc_node
             |
             +-> kmem_cache_node_init
```

Arguments
----------------------------------------

path: mm/slab.c
```
/* Called with slab_mutex held always */
static int enable_cpucache(struct kmem_cache *cachep, gfp_t gfp)
{
    int err;
    int limit = 0;
    int shared = 0;
    int batchcount = 0;
```

batchcount
----------------------------------------

```
    if (!is_root_cache(cachep)) {
        struct kmem_cache *root = memcg_root_cache(cachep);
        limit = root->limit;
        shared = root->shared;
        batchcount = root->batchcount;
    }

    if (limit && shared && batchcount)
        goto skip_setup;
    /*
     * The head array serves three purposes:
     * - create a LIFO ordering, i.e. return objects that are cache-warm
     * - reduce the number of spinlock operations.
     * - reduce the number of linked list operations on the slab and
     *   bufctl chains: array operations are cheaper.
     * The numbers are guessed, we should auto-tune as described by
     * Bonwick.
     */
    if (cachep->size > 131072)
        limit = 1;
    else if (cachep->size > PAGE_SIZE)
        limit = 8;
    else if (cachep->size > 1024)
        limit = 24;
    else if (cachep->size > 256)
        limit = 54;
    else
        limit = 120;

    /*
     * CPU bound tasks (e.g. network routing) can exhibit cpu bound
     * allocation behaviour: Most allocs on one cpu, most free operations
     * on another cpu. For these cases, an efficient object passing between
     * cpus is necessary. This is provided by a shared array. The array
     * replaces Bonwick's magazine layer.
     * On uniprocessor, it's functionally equivalent (but less efficient)
     * to a larger limit. Thus disabled by default.
     */
    shared = 0;
    if (cachep->size <= PAGE_SIZE && num_possible_cpus() > 1)
        shared = 8;

#if DEBUG
    /*
     * With debugging enabled, large batchcount lead to excessively long
     * periods with disabled local interrupts. Limit the batchcount
     */
    if (limit > 32)
        limit = 32;
#endif
    batchcount = (limit + 1) / 2;
```

do_tune_cpucache
----------------------------------------

```
skip_setup:
    err = do_tune_cpucache(cachep, limit, batchcount, shared, gfp);
    if (err)
        printk(KERN_ERR "enable_cpucache failed for %s, error %d.\n",
               cachep->name, -err);
    return err;
}
```

https://github.com/novelinux/linux-4.x.y/blob/master/mm/slab.c/do_tune_cpucache.md
