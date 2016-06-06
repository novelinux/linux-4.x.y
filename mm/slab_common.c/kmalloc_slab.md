kmalloc_slab
========================================

Arguments
----------------------------------------

path: mm/slab_common.c
```
/*
 * Find the kmem_cache structure that serves a given size of
 * allocation
 */
struct kmem_cache *kmalloc_slab(size_t size, gfp_t flags)
{
    int index;

    if (unlikely(size > KMALLOC_MAX_SIZE)) {
        WARN_ON_ONCE(!(flags & __GFP_NOWARN));
        return NULL;
    }
```

index
----------------------------------------

```
    if (size <= 192) {
        if (!size)
            return ZERO_SIZE_PTR;

        index = size_index[size_index_elem(size)];
    } else
        index = fls(size - 1);
```

### size_index_elem

https://github.com/novelinux/linux-4.x.y/tree/master/mm/slab_common.c/size_index_elem.md

### size_index

https://github.com/novelinux/linux-4.x.y/tree/master/mm/slab_common.c/size_index.md

kmalloc_caches
----------------------------------------

```
#ifdef CONFIG_ZONE_DMA
    if (unlikely((flags & GFP_DMA)))
        return kmalloc_dma_caches[index];

#endif
    return kmalloc_caches[index];
}
```

https://github.com/novelinux/linux-4.x.y/tree/master/mm/slab_common.c/kmalloc_caches.md
