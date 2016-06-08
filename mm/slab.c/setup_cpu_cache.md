setup_cpu_cache
========================================

Arguments
----------------------------------------

path: mm/slab.c
```
static int __init_refok setup_cpu_cache(struct kmem_cache *cachep, gfp_t gfp)
{
```

enable_cpucache
----------------------------------------

```
    if (slab_state >= FULL)
        return enable_cpucache(cachep, gfp);
```

https://github.com/novelinux/linux-4.x.y/blob/master/mm/slab.c/enable_cpucache.md

alloc_kmem_cache_cpus
----------------------------------------

```
    cachep->cpu_cache = alloc_kmem_cache_cpus(cachep, 1, 1);
    if (!cachep->cpu_cache)
        return 1;

    if (slab_state == DOWN) {
        /* Creation of first cache (kmem_cache). */
        set_up_node(kmem_cache, CACHE_CACHE);
    } else if (slab_state == PARTIAL) {
        /* For kmem_cache_node */
        set_up_node(cachep, SIZE_NODE);
    } else {
        int node;

        for_each_online_node(node) {
            cachep->node[node] = kmalloc_node(
                sizeof(struct kmem_cache_node), gfp, node);
            BUG_ON(!cachep->node[node]);
            kmem_cache_node_init(cachep->node[node]);
        }
    }

    cachep->node[numa_mem_id()]->next_reap =
            jiffies + REAPTIMEOUT_NODE +
            ((unsigned long)cachep) % REAPTIMEOUT_NODE;

    cpu_cache_get(cachep)->avail = 0;
    cpu_cache_get(cachep)->limit = BOOT_CPUCACHE_ENTRIES;
    cpu_cache_get(cachep)->batchcount = 1;
    cpu_cache_get(cachep)->touched = 0;
    cachep->batchcount = 1;
    cachep->limit = BOOT_CPUCACHE_ENTRIES;
    return 0;
}
```