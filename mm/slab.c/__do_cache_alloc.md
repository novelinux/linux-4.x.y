__do_cache_alloc
========================================

path: mm/slab.c
```
#ifdef CONFIG_NUMA
static __always_inline void *
__do_cache_alloc(struct kmem_cache *cache, gfp_t flags)
{
    void *objp;

    if (current->mempolicy || cpuset_do_slab_mem_spread()) {
        objp = alternate_node_alloc(cache, flags);
        if (objp)
            goto out;
    }
    objp = ____cache_alloc(cache, flags);

    /*
     * We may just have run out of memory on the local node.
     * ____cache_alloc_node() knows how to locate memory on other nodes
     */
    if (!objp)
        objp = ____cache_alloc_node(cache, flags, numa_mem_id());

  out:
    return objp;
}
#else

static __always_inline void *
__do_cache_alloc(struct kmem_cache *cachep, gfp_t flags)
{
    return ____cache_alloc(cachep, flags);
}

#endif /* CONFIG_NUMA */
```

____cache_alloc
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/mm/slab.c/____cache_alloc.md
