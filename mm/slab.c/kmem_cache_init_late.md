kmem_cache_init_late
========================================

Code Flow
----------------------------------------

```
kmem_cache_init_late
 |
 +-> enable_cpucache
 |
 +-> register_cpu_notifier
```

Arguments
----------------------------------------

path: mm/slab.c
```
void __init kmem_cache_init_late(void)
{
    struct kmem_cache *cachep;

    slab_state = UP;
```

enable_cpucache
----------------------------------------

```
    /* 6) resize the head arrays to their final sizes */
    mutex_lock(&slab_mutex);
    list_for_each_entry(cachep, &slab_caches, list)
        if (enable_cpucache(cachep, GFP_NOWAIT))
            BUG();
    mutex_unlock(&slab_mutex);
```

https://github.com/novelinux/linux-4.x.y/blob/master/mm/slab.c/enable_cpucache.md

register_cpu_notifier
----------------------------------------

```
    /* Done! */
    slab_state = FULL;

    /*
     * Register a cpu startup notifier callback that initializes
     * cpu_cache_get for all new cpus
     */
    register_cpu_notifier(&cpucache_notifier);

#ifdef CONFIG_NUMA
    /*
     * Register a memory hotplug callback that initializes and frees
     * node.
     */
    hotplug_memory_notifier(slab_memory_callback, SLAB_CALLBACK_PRI);
#endif

    /*
     * The reap timers are started later, with a module init call: That part
     * of the kernel is not yet operational.
     */
}
```
