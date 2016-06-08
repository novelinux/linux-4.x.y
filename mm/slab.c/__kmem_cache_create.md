__kmem_cache_create
========================================

Argumenst
----------------------------------------

path: mm/slab.c
```
/**
 * __kmem_cache_create - Create a cache.
 * @cachep: cache management descriptor
 * @flags: SLAB flags
 *
 * Returns a ptr to the cache on success, NULL on failure.
 * Cannot be called within a int, but can be interrupted.
 * The @ctor is run when new pages are allocated by the cache.
 *
 * The flags are
 *
 * %SLAB_POISON - Poison the slab with a known test pattern (a5a5a5a5)
 * to catch references to uninitialised memory.
 *
 * %SLAB_RED_ZONE - Insert `Red' zones around the allocated memory to check
 * for buffer overruns.
 *
 * %SLAB_HWCACHE_ALIGN - Align the objects in this cache to a hardware
 * cacheline.  This can be beneficial if you're counting cycles as closely
 * as davem.
 */
int
__kmem_cache_create (struct kmem_cache *cachep, unsigned long flags)
{
    size_t left_over, freelist_size;
    size_t ralign = BYTES_PER_WORD;
    gfp_t gfp;
    int err;
    size_t size = cachep->size;
```

Check size, align, gfp, flags
----------------------------------------

```
    /*
     * Check that size is in terms of words.  This is needed to avoid
     * unaligned accesses for some archs when redzoning is used, and makes
     * sure any on-slab bufctl's are also correctly aligned.
     */
    // 对象长度向上舍入到处理器字长的倍数.
    if (size & (BYTES_PER_WORD - 1)) {
        size += (BYTES_PER_WORD - 1);
        size &= ~(BYTES_PER_WORD - 1);
    }

    if (flags & SLAB_RED_ZONE) {
        ralign = REDZONE_ALIGN;
        /* If redzoning, ensure that the second redzone is suitably
         * aligned, by adjusting the object size accordingly. */
        size += REDZONE_ALIGN - 1;
        size &= ~(REDZONE_ALIGN - 1);
    }

    /* 3) caller mandated alignment */
    if (ralign < cachep->align) {
        ralign = cachep->align;
    }
    /* disable debug if necessary */
    if (ralign > __alignof__(unsigned long long))
        flags &= ~(SLAB_RED_ZONE | SLAB_STORE_USER);
    /*
     * 4) Store it.
     */
    cachep->align = ralign;

    if (slab_is_available())
        gfp = GFP_KERNEL;
    else
        gfp = GFP_NOWAIT;

    /*
     * Determine if the slab management is 'on' or 'off' slab.
     * (bootstrapping cannot cope with offslab caches so don't do
     * it too early on. Always use on-slab management when
     * SLAB_NOLEAKTRACE to avoid recursive calls into kmemleak)
     */
    if ((size >= (PAGE_SIZE >> 5)) && !slab_early_init &&
        !(flags & SLAB_NOLEAKTRACE))
        /*
         * Size is large, assume best to place the slab management obj
         * off-slab (should allow better packing of objs).
         */
        flags |= CFLGS_OFF_SLAB;

    /* ALIGN(x, y)是内核提供的一个标准宏，计算足以容纳对象x的空间长度，同时要求该
     * 空间长度是align的整数倍。
     */
    size = ALIGN(size, cachep->align);
    /*
     * We should restrict the number of objects in a slab to implement
     * byte sized index. Refer comment on SLAB_OBJ_MIN_SIZE definition.
     */
    if (FREELIST_BYTE_INDEX && size < SLAB_OBJ_MIN_SIZE)
        size = ALIGN(SLAB_OBJ_MIN_SIZE, cachep->align);

    left_over = calculate_slab_order(cachep, size, cachep->align, flags);

    if (!cachep->num)
        return -E2BIG;

    freelist_size = calculate_freelist_size(cachep->num, cachep->align);

    /*
     * If the slab has been placed off-slab, and we have enough space then
     * move it on-slab. This is at the expense of any extra colouring.
     */
    if (flags & CFLGS_OFF_SLAB && left_over >= freelist_size) {
        flags &= ~CFLGS_OFF_SLAB;
        left_over -= freelist_size;
    }

    if (flags & CFLGS_OFF_SLAB) {
        /* really off slab. No need for manual alignment */
        freelist_size = calculate_freelist_size(cachep->num, 0);

#ifdef CONFIG_PAGE_POISONING
        /* If we're going to use the generic kernel_map_pages()
         * poisoning, then it's going to smash the contents of
         * the redzone and userword anyhow, so switch them off.
         */
        if (size % PAGE_SIZE == 0 && flags & SLAB_POISON)
            flags &= ~(SLAB_RED_ZONE | SLAB_STORE_USER);
#endif
    }
```

Set cachep
----------------------------------------

```
    cachep->colour_off = cache_line_size();
    /* Offset must be a multiple of the alignment. */
    if (cachep->colour_off < cachep->align)
        cachep->colour_off = cachep->align;
    cachep->colour = left_over / cachep->colour_off;
    cachep->freelist_size = freelist_size;
    cachep->flags = flags;
    cachep->allocflags = __GFP_COMP;
    if (CONFIG_ZONE_DMA_FLAG && (flags & SLAB_CACHE_DMA))
        cachep->allocflags |= GFP_DMA;
    cachep->size = size;
    cachep->reciprocal_buffer_size = reciprocal_value(size);

    if (flags & CFLGS_OFF_SLAB) {
        cachep->freelist_cache = kmalloc_slab(freelist_size, 0u);
        /*
         * This is a possibility for one of the kmalloc_{dma,}_caches.
         * But since we go off slab only for object size greater than
         * PAGE_SIZE/8, and kmalloc_{dma,}_caches get created
         * in ascending order,this should not happen at all.
         * But leave a BUG_ON for some lucky dude.
         */
        BUG_ON(ZERO_OR_NULL_PTR(cachep->freelist_cache));
    }

    err = setup_cpu_cache(cachep, gfp);
    if (err) {
        __kmem_cache_shutdown(cachep);
        return err;
    }

    return 0;
}
```
