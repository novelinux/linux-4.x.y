__do_kmalloc
========================================

Arguments
----------------------------------------

path: mm/slab.c
```
/**
 * __do_kmalloc - allocate memory
 * @size: how many bytes of memory are required.
 * @flags: the type of memory to allocate (see kmalloc).
 * @caller: function caller for debug tracking of the caller
 */
static __always_inline void *__do_kmalloc(size_t size, gfp_t flags,
                      unsigned long caller)
{
    struct kmem_cache *cachep;
    void *ret;
```

kmalloc_slab
----------------------------------------

```
    cachep = kmalloc_slab(size, flags);
    if (unlikely(ZERO_OR_NULL_PTR(cachep)))
        return cachep;
```

在kmalloc_slab找到适当的缓存后,遍历所有可能的kmalloc长度，找到一个匹配的缓存.

https://github.com/novelinux/linux-4.x.y/blob/master/mm/slab_common.c/kmalloc_slab.md

slab_alloc
----------------------------------------

```
    ret = slab_alloc(cachep, flags, caller);

    trace_kmalloc(caller, ret,
              size, cachep->size, flags);

    return ret;
}
```

https://github.com/novelinux/linux-4.x.y/blob/master/mm/slab.c/slab_alloc.md