create_boot_cache
========================================

Arguments
----------------------------------------

path: mm/slab_common.c
```
/* Create a cache during boot when no slab services are available yet */
void __init create_boot_cache(struct kmem_cache *s, const char *name, size_t size,
        unsigned long flags)
{
    int err;
```

slab_init_memcg_params
----------------------------------------

```
    s->name = name;
    s->size = s->object_size = size;
    s->align = calculate_alignment(flags, ARCH_KMALLOC_MINALIGN, size);

    slab_init_memcg_params(s);
```

__kmem_cache_create
----------------------------------------

```
    err = __kmem_cache_create(s, flags);

    if (err)
        panic("Creation of kmalloc slab %s size=%zu failed. Reason %d\n",
                    name, size, err);

    s->refcount = -1;    /* Exempt from merging for now */
}
```

https://github.com/novelinux/linux-4.x.y/tree/master/mm/slab.c/__kmem_cache_create.md
