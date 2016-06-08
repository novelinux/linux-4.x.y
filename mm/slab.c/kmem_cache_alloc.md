kmem_cache_alloc
========================================

kmem_cache_alloc用于从特定的缓存获取对象。类似于所有的malloc函数，其结果可能是指向分配内存区的
指针，也可能分配失败，返回NULL指针。

Code Flow
----------------------------------------

```
kmem_cache_alloc
 |
 +-> slab_alloc
```

Arguments
----------------------------------------

该函数需要两个参数：用于获取对象的缓存，以及精确描述分配特征的标志变量。

path: mm/slab.c
```
/**
 * kmem_cache_alloc - Allocate an object
 * @cachep: The cache to allocate from.
 * @flags: See kmalloc().
 *
 * Allocate an object from this cache.  The flags are only relevant
 * if the cache has no available objects.
 */
void *kmem_cache_alloc(struct kmem_cache *cachep, gfp_t flags)
{
```

slab_alloc
----------------------------------------

```
    void *ret = slab_alloc(cachep, flags, _RET_IP_);

    trace_kmem_cache_alloc(_RET_IP_, ret,
                   cachep->object_size, cachep->size, flags);

    return ret;
}
EXPORT_SYMBOL(kmem_cache_alloc);
```

https://github.com/novelinux/linux-4.x.y/blob/master/mm/slab.c/slab_alloc.md
