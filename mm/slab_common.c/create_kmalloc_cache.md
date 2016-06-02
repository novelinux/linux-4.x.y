create_kmalloc_cache
========================================

Argumenst
----------------------------------------

path: mm/slab_common.c
```
struct kmem_cache *__init create_kmalloc_cache(const char *name, size_t size,
                unsigned long flags)
{
```

kmem_cache_zalloc
----------------------------------------

```
    struct kmem_cache *s = kmem_cache_zalloc(kmem_cache, GFP_NOWAIT);

    if (!s)
        panic("Out of memory when creating slab %s\n", name);
```

create_boot_cache
----------------------------------------

```
    create_boot_cache(s, name, size, flags);
    list_add(&s->list, &slab_caches);
    s->refcount = 1;
    return s;
}
```

https://github.com/novelinux/linux-4.x.y/tree/master/mm/slab_common.c/create_boot_cache.md
