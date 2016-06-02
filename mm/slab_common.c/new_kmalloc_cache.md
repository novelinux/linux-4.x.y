new_kmalloc_cache
========================================

path: mm/slab_common.c
```
static void __init new_kmalloc_cache(int idx, unsigned long flags)
{
    kmalloc_caches[idx] = create_kmalloc_cache(kmalloc_info[idx].name,
                    kmalloc_info[idx].size, flags);
}
```

create_kmalloc_cache
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/mm/slab_common.c/create_kmalloc_cache.md
