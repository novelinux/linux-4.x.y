do_tune_cpucache
========================================

path: mm/slab.c
```
static int do_tune_cpucache(struct kmem_cache *cachep, int limit,
                int batchcount, int shared, gfp_t gfp)
{
    int ret;
    struct kmem_cache *c;

    ret = __do_tune_cpucache(cachep, limit, batchcount, shared, gfp);

    if (slab_state < FULL)
        return ret;

    if ((ret < 0) || !is_root_cache(cachep))
        return ret;

    lockdep_assert_held(&slab_mutex);
    for_each_memcg_cache(c, cachep) {
        /* return value determined by the root cache only */
        __do_tune_cpucache(c, limit, batchcount, shared, gfp);
    }

    return ret;
}
```

__do_tune_cpucache
----------------------------------------

https://github.com/novelinux/linux-4.x.y/blob/master/mm/slab.c/__do_tune_cpucache.md
