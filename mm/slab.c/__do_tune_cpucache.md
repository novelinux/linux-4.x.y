__do_tune_cpucache
========================================

Arguments
----------------------------------------

path: mm/slab.c
```
/* Always called with the slab_mutex held */
static int __do_tune_cpucache(struct kmem_cache *cachep, int limit,
                int batchcount, int shared, gfp_t gfp)
{
    struct array_cache __percpu *cpu_cache, *prev;
    int cpu;
```

alloc_kmem_cache_cpus
----------------------------------------

```
    cpu_cache = alloc_kmem_cache_cpus(cachep, limit, batchcount);
    if (!cpu_cache)
        return -ENOMEM;

    prev = cachep->cpu_cache;
    cachep->cpu_cache = cpu_cache;
    kick_all_cpus_sync();

    check_irq_on();
    cachep->batchcount = batchcount;
    cachep->limit = limit;
    cachep->shared = shared;

    if (!prev)
        goto alloc_node;

    for_each_online_cpu(cpu) {
        LIST_HEAD(list);
        int node;
        struct kmem_cache_node *n;
        struct array_cache *ac = per_cpu_ptr(prev, cpu);

        node = cpu_to_mem(cpu);
        n = get_node(cachep, node);
        spin_lock_irq(&n->list_lock);
        free_block(cachep, ac->entry, ac->avail, node, &list);
        spin_unlock_irq(&n->list_lock);
        slabs_destroy(cachep, &list);
    }
    free_percpu(prev);
```

alloc_kmem_cache_node
----------------------------------------

```
alloc_node:
    return alloc_kmem_cache_node(cachep, gfp);
}
```

https://github.com/novelinux/linux-4.x.y/blob/master/mm/slab.c/alloc_kmem_cache_node.md
