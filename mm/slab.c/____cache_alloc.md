____cache_alloc
========================================

Arguments
----------------------------------------

path: mm/slab.c
```
static inline void *____cache_alloc(struct kmem_cache *cachep, gfp_t flags)
{
    void *objp;
    struct array_cache *ac;
    bool force_refill = false;

    check_irq_off();
```

cpu_cache_get
----------------------------------------

如果per-CPU缓存中有空闲对象，则从中获取。但如果其中的所有对象都已经分配，则必须重新填充缓存。
在最坏的情况下，可能需要新建一个slab。如果在per-CPU缓存中有对象，那么____cache_alloc检查相对容易，
如下列代码片段所示：

```
    ac = cpu_cache_get(cachep);
```

https://github.com/novelinux/linux-4.x.y/tree/master/mm/slab.c/cpu_cache_get.md

ac_get_obj
----------------------------------------

```
    if (likely(ac->avail)) {
        ac->touched = 1;
        objp = ac_get_obj(cachep, ac, flags, false);

        /*
         * Allow for the possibility all avail objects are not allowed
         * by the current flags
         */
        if (objp) {
            STATS_INC_ALLOCHIT(cachep);
            goto out;
        }
        force_refill = true;
    }
```

https://github.com/novelinux/linux-4.x.y/tree/master/mm/slab.c/ac_get_obj.md

cache_alloc_refill
----------------------------------------

在per-CPU缓存中没有对象时，工作负荷会加重。该情形下所需的重新填充操作由cache_alloc_refill实现，
在per-CPU缓存无法直接满足分配请求时，则调用该函数。

```
    STATS_INC_ALLOCMISS(cachep);
    objp = cache_alloc_refill(cachep, flags, force_refill);
```

https://github.com/novelinux/linux-4.x.y/tree/master/mm/slab.c/cache_alloc_refill.md

Return
----------------------------------------

```
    /*
     * the 'ac' may be updated by cache_alloc_refill(),
     * and kmemleak_erase() requires its correct value.
     */
    ac = cpu_cache_get(cachep);

out:
    /*
     * To avoid a false negative, if an object that is in one of the
     * per-CPU caches is leaked, we need to make sure kmemleak doesn't
     * treat the array pointers as a reference to the object.
     */
    if (objp)
        kmemleak_erase(&ac->entry[ac->avail]);
    return objp;
}
```