kmalloc
========================================

分配长度为size字节的一个内存区，并返回指向该内存区起始处的一个void指针。如果没有足够内存
（在内核中这种情形不大可能，但却始终要考虑到），则结果为NULL指针。flags参数使用GFP_常数，
来指定分配内存的具体内存域，例如GFP_DMA指定分配适合于DMA的内存区。

Comments
----------------------------------------

path: include/linux/slab.h
```
/**
 * kmalloc - allocate memory
 * @size: how many bytes of memory are required.
 * @flags: the type of memory to allocate.
 *
 * kmalloc is the normal method of allocating memory
 * for objects smaller than page size in the kernel.
 *
 * The @flags argument may be one of:
 *
 * %GFP_USER - Allocate memory on behalf of user.  May sleep.
 *
 * %GFP_KERNEL - Allocate normal kernel ram.  May sleep.
 *
 * %GFP_ATOMIC - Allocation will not sleep.  May use emergency pools.
 *   For example, use this inside interrupt handlers.
 *
 * %GFP_HIGHUSER - Allocate pages from high memory.
 *
 * %GFP_NOIO - Do not do any I/O at all while trying to get memory.
 *
 * %GFP_NOFS - Do not make any fs calls while trying to get memory.
 *
 * %GFP_NOWAIT - Allocation will not sleep.
 *
 * %__GFP_THISNODE - Allocate node-local memory only.
 *
 * %GFP_DMA - Allocation suitable for DMA.
 *   Should only be used for kmalloc() caches. Otherwise, use a
 *   slab created with SLAB_DMA.
 *
 * Also it is possible to set different flags by OR'ing
 * in one or more of the following additional @flags:
 *
 * %__GFP_COLD - Request cache-cold pages instead of
 *   trying to return cache-warm pages.
 *
 * %__GFP_HIGH - This allocation has high priority and may use emergency pools.
 *
 * %__GFP_NOFAIL - Indicate that this allocation is in no way allowed to fail
 *   (think twice before using).
 *
 * %__GFP_NORETRY - If memory is not immediately available,
 *   then give up at once.
 *
 * %__GFP_NOWARN - If allocation fails, don't issue any warnings.
 *
 * %__GFP_REPEAT - If allocation fails initially, try once more before failing.
 *
 * There are other flags available as well, but these are not intended
 * for general use, and so are not documented here. For a full list of
 * potential flags, always refer to linux/gfp.h.
 */
```

Arguments
----------------------------------------

```
static __always_inline void *kmalloc(size_t size, gfp_t flags)
{
```

__kmalloc
----------------------------------------

```
    if (__builtin_constant_p(size)) {
        if (size > KMALLOC_MAX_CACHE_SIZE)
            return kmalloc_large(size, flags);
#ifndef CONFIG_SLOB
        if (!(flags & GFP_DMA)) {
            int index = kmalloc_index(size);

            if (!index)
                return ZERO_SIZE_PTR;

            return kmem_cache_alloc_trace(kmalloc_caches[index],
                    flags, size);
        }
#endif
    }
    return __kmalloc(size, flags);
}
```

https://github.com/novelinux/linux-4.x.y/tree/master/mm/slab.c/__kmalloc.c
