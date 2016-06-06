__cache_free
========================================

Arguments
----------------------------------------

path: mm/slab.c
```
/*
 * Release an obj back to its cache. If the obj has a constructed state, it must
 * be in this state _before_ it is released.  Called with disabled ints.
 */
static inline void __cache_free(struct kmem_cache *cachep, void *objp,
                unsigned long caller)
{
    struct array_cache *ac = cpu_cache_get(cachep);

    check_irq_off();
    kmemleak_free_recursive(objp, cachep->flags);
    objp = cache_free_debugcheck(cachep, objp, caller);

    kmemcheck_slab_free(cachep, objp, cachep->object_size);

    /*
     * Skip calling cache_free_alien() when the platform is not numa.
     * This will avoid cache misses that happen while accessing slabp (which
     * is per page memory  reference) to get nodeid. Instead use a global
     * variable to skip the call, which is mostly likely to be present in
     * the cache.
     */
    if (nr_online_nodes > 1 && cache_free_alien(cachep, objp))
        return;
```

ac_put_obj
----------------------------------------

```
    if (ac->avail < ac->limit) {
        STATS_INC_FREEHIT(cachep);
    } else {
        STATS_INC_FREEMISS(cachep);
        cache_flusharray(cachep, ac);
    }

    ac_put_obj(cachep, ac, objp);
}
```

如果per-CPU缓存中的对象数目低于允许的限制，则调用ac_put_obj在其中存储一个指向缓存中对象的指针。
否则，必须将一些对象（准确的数目由array_cache->batchcount给出）从缓存移回slab，从编号最低的
数组元素开始：缓存的实现依据先进先出原理，这些对象在数组中已经很长时间，因此不太可能仍然驻留在
CPU高速缓存中。具体的实现委托给cache_flusharray。

### cache_flusharray

https://github.com/novelinux/linux-4.x.y/blob/master/mm/slab.c/cache_flusharray.md

### ac_put_obj

https://github.com/novelinux/linux-4.x.y/blob/master/mm/slab.c/ac_put_obj.md
