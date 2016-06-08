slab_alloc
========================================

Code Flow
----------------------------------------

```
slab_alloc
 |
 +-> __do_cache_alloc
     |
     +-> ____cache_alloc
         |
         +-> cpu_cache_get -> ac_get_obj -> __ac_get_obj
         |
         +-> cache_alloc_refill
             |
             +-> cpu_cache_get
             |
             +-> get_node
             |
             +-> slab_get_obj
             |
             +-> ac_put_obj
             |
             +-> cache_grow
```

Arugments
----------------------------------------

path: mm/slab.c
```
static __always_inline void *
slab_alloc(struct kmem_cache *cachep, gfp_t flags, unsigned long caller)
{
    unsigned long save_flags;
    void *objp;

    flags &= gfp_allowed_mask;

    lockdep_trace_alloc(flags);

    if (slab_should_failslab(cachep, flags))
        return NULL;

    cachep = memcg_kmem_get_cache(cachep, flags);

    cache_alloc_debugcheck_before(cachep, flags);
```

__do_cache_alloc
----------------------------------------

```
    local_irq_save(save_flags);
    objp = __do_cache_alloc(cachep, flags);
    local_irq_restore(save_flags);
```

https://github.com/novelinux/linux-4.x.y/tree/master/mm/slab.c/__do_cache_alloc.md

kmemcheck_slab_alloc
----------------------------------------

```
    objp = cache_alloc_debugcheck_after(cachep, flags, objp, caller);
    kmemleak_alloc_recursive(objp, cachep->object_size, 1, cachep->flags,
                 flags);
    prefetchw(objp);

    if (likely(objp)) {
        kmemcheck_slab_alloc(cachep, flags, objp, cachep->object_size);
        if (unlikely(flags & __GFP_ZERO))
            memset(objp, 0, cachep->object_size);
    }

    memcg_kmem_put_cache(cachep);
    return objp;
}
```