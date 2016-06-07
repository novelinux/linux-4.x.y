kmem_cache_alloc_node
========================================

path: include/linux/slab.h
```
#ifdef CONFIG_NUMA
void *__kmalloc_node(size_t size, gfp_t flags, int node) __assume_kmalloc_alignment;
void *kmem_cache_alloc_node(struct kmem_cache *, gfp_t flags, int node) __assume_slab_alignment;
#else
static __always_inline void *__kmalloc_node(size_t size, gfp_t flags, int node)
{
    return __kmalloc(size, flags);
}

static __always_inline void *kmem_cache_alloc_node(struct kmem_cache *s, gfp_t flags, int node)
{
    return kmem_cache_alloc(s, flags);
}
#endif
```

kmem_cache_alloc
----------------------------------------

https://github.com/novelinux/linux-4.x.y/blob/master/mm/slab.c/kmem_cache_alloc.md