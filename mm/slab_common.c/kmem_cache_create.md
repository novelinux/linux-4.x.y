kmem_cache_create
========================================

Comments
----------------------------------------

path: mm/slab_common.c
```
/*
 * kmem_cache_create - Create a cache.
 * @name: A string which is used in /proc/slabinfo to identify this cache.
 * @size: The size of objects to be created in this cache.
 * @align: The required alignment for the objects.
 * @flags: SLAB flags
 * @ctor: A constructor for the objects.
 *
 * Returns a ptr to the cache on success, NULL on failure.
 * Cannot be called within a interrupt, but can be interrupted.
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
```

Arguments
----------------------------------------

```
struct kmem_cache *
kmem_cache_create(const char *name, size_t size, size_t align,
          unsigned long flags, void (*ctor)(void *))
{
    struct kmem_cache *s;
    const char *cache_name;
    int err;

    get_online_cpus();
    get_online_mems();
    memcg_get_cache_ids();
```

kmem_cache_sanity_check
----------------------------------------

```
    mutex_lock(&slab_mutex);

    err = kmem_cache_sanity_check(name, size);
    if (err) {
        s = NULL;    /* suppress uninit var warning */
        goto out_unlock;
    }
```

__kmem_cache_alias
----------------------------------------

```
    /*
     * Some allocators will constraint the set of valid flags to a subset
     * of all flags. We expect them to define CACHE_CREATE_MASK in this
     * case, and we'll just provide them with a sanitized version of the
     * passed flags.
     */
    flags &= CACHE_CREATE_MASK;

    s = __kmem_cache_alias(name, size, align, flags, ctor);
    if (s)
        goto out_unlock;

    cache_name = kstrdup_const(name, GFP_KERNEL);
    if (!cache_name) {
        err = -ENOMEM;
        goto out_unlock;
    }
```

do_kmem_cache_create
----------------------------------------

```
    s = do_kmem_cache_create(cache_name, size, size,
                 calculate_alignment(flags, align, size),
                 flags, ctor, NULL, NULL);
    if (IS_ERR(s)) {
        err = PTR_ERR(s);
        kfree_const(cache_name);
    }
```

https://github.com/novelinux/linux-4.x.y/blob/master/mm/slab_common.c/do_kmem_cache_create.md

out_unlock
----------------------------------------

```
out_unlock:
    mutex_unlock(&slab_mutex);

    memcg_put_cache_ids();
    put_online_mems();
    put_online_cpus();

    if (err) {
        if (flags & SLAB_PANIC)
            panic("kmem_cache_create: Failed to create slab '%s'. Error %d\n",
                name, err);
        else {
            printk(KERN_WARNING "kmem_cache_create(%s) failed with error %d",
                name, err);
            dump_stack();
        }
        return NULL;
    }
    return s;
}
EXPORT_SYMBOL(kmem_cache_create);
```