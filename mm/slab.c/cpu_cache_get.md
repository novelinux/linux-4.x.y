cpu_cache_get
========================================

path: mm/slab.c
```
static inline struct array_cache *cpu_cache_get(struct kmem_cache *cachep)
{
    return this_cpu_ptr(cachep->cpu_cache);
}
```