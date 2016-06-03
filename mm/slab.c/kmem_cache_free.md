kmem_cache_free
========================================

如果一个分配的对象已经不再需要，那么必须使用kmem_cache_free返回给slab分配器。

Arguments
----------------------------------------

path: mm/slab.c
```
/**
 * kmem_cache_free - Deallocate an object
 * @cachep: The cache the allocation was from.
 * @objp: The previously allocated object.
 *
 * Free an object which was previously allocated from this
 * cache.
 */
void kmem_cache_free(struct kmem_cache *cachep, void *objp)
{
```

__cache_free
----------------------------------------

```
    unsigned long flags;
    cachep = cache_from_obj(cachep, objp);
    if (!cachep)
        return;

    local_irq_save(flags);
    debug_check_no_locks_freed(objp, cachep->object_size);
    if (!(cachep->flags & SLAB_DEBUG_OBJECTS))
        debug_check_no_obj_freed(objp, cachep->object_size);
    __cache_free(cachep, objp, _RET_IP_);
    local_irq_restore(flags);

    trace_kmem_cache_free(_RET_IP_, objp);
}
EXPORT_SYMBOL(kmem_cache_free);
```

https://github.com/novelinux/linux-4.x.y/blob/master/mm/slab.c/__cache_free.md
