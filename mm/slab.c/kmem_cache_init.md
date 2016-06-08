kmem_cache_init
========================================

初看起来，slab系统的初始化不是特别麻烦，因为伙伴系统已经完全启用，内核没有受到其他特别的限制。
尽管如此，由于slab分配器的结构所致，这里有一个鸡与蛋的问题。为初始化slab数据结构，内核需要
若干远小于一整页的内存块，这些最适合由kmalloc分配。这里是关键所在：只在slab系统已经启用之后，
才能使用kmalloc。更确切地说，该问题涉及kmalloc的per-CPU缓存的初始化。在这些缓存能够初始化之前，
kmalloc必须可以用来分配所需的内存空间，而kmalloc自身也正处于初始化的过程中。换句话说，
kmalloc只能在kmalloc已经初始化之后初始化，这是个不可能的场景。因此内核必须借助一些技巧。
kmem_cache_init函数用于初始化slab分配器。它在内核初始化阶段（start_kernel）、伙伴系统启用之后
调用。但在多处理器系统上，启动CPU此时正在运行，而其他CPU尚未初始化。kmem_cache_init采用了一个
多步骤过程，逐步激活slab分配器。

Code Flow
----------------------------------------

```
kmem_cache_init
 |
 +-> kmem_cache_node_init (init_kmem_cache_node)
 |
 +-> create_boot_cache <-------+
 |   |                         |
 |   +-> __kmem_cache_create   |
 |                             |
 +-> create_kmalloc_cache -----+
 |                             |
 +-> create_kmalloc_caches     |
     |                         |
     +-> new_kmalloc_cache     |
     |                         |
     +-> create_kmalloc_cache -+
```

Arguments
----------------------------------------

path: mm/slab.c
```
/*
 * Initialisation.  Called after the page allocator have been initialised and
 * before smp_init().
 */
void __init kmem_cache_init(void)
{
    int i;

    BUILD_BUG_ON(sizeof(((struct page *)NULL)->lru) <
                    sizeof(struct rcu_head));
```

kmem_cache_boot
----------------------------------------

```
    kmem_cache = &kmem_cache_boot;
```

kmem_cache_init创建系统中的第一个slab缓存，以便为kmem_cache的实例提供内存。为此，内核使用的
主要是在编译时创建的静态数据。实际上，一个静态数据结构(initarray_cache)用作per-CPU数组。
该缓存的名称是kmem_cache_boot。

https://github.com/novelinux/linux-4.x.y/tree/master/mm/slab.c/kmem_cache_boot.md

kmem_cache_node_init
----------------------------------------

```
    if (num_possible_nodes() == 1)
        use_alien_caches = 0;

    for (i = 0; i < NUM_INIT_LISTS; i++)
        kmem_cache_node_init(&init_kmem_cache_node[i]);
```

### init_kmem_cache_node

https://github.com/novelinux/linux-4.x.y/tree/master/mm/slab.c/init_kmem_cache_node.md

### kmem_cache_node_init

https://github.com/novelinux/linux-4.x.y/tree/master/mm/slab.c/kmem_cache_node_init.md

create_boot_cache
----------------------------------------

```
    /*
     * Fragmentation resistance on low memory - only use bigger
     * page orders on machines with more than 32MB of memory if
     * not overridden on the command line.
     */
    if (!slab_max_order_set && totalram_pages > (32 << 20) >> PAGE_SHIFT)
        slab_max_order = SLAB_MAX_ORDER_HI;

    /* Bootstrap is tricky, because several objects are allocated
     * from caches that do not exist yet:
     * 1) initialize the kmem_cache cache: it contains the struct
     *    kmem_cache structures of all caches, except kmem_cache itself:
     *    kmem_cache is statically allocated.
     *    Initially an __init data area is used for the head array and the
     *    kmem_cache_node structures, it's replaced with a kmalloc allocated
     *    array at the end of the bootstrap.
     * 2) Create the first kmalloc cache.
     *    The struct kmem_cache for the new cache is allocated normally.
     *    An __init data area is used for the head array.
     * 3) Create the remaining kmalloc caches, with minimally sized
     *    head arrays.
     * 4) Replace the __init data head arrays for kmem_cache and the first
     *    kmalloc cache with kmalloc allocated arrays.
     * 5) Replace the __init data for kmem_cache_node for kmem_cache and
     *    the other cache's with kmalloc allocated memory.
     * 6) Resize the head arrays of the kmalloc caches to their final sizes.
     */

    /* 1) create the kmem_cache */

    /*
     * struct kmem_cache size depends on nr_node_ids & nr_cpu_ids
     */
    create_boot_cache(kmem_cache, "kmem_cache",
        offsetof(struct kmem_cache, node) +
                  nr_node_ids * sizeof(struct kmem_cache_node *),
                  SLAB_HWCACHE_ALIGN);
    list_add(&kmem_cache->list, &slab_caches);
    slab_state = PARTIAL;
```

调用create_boot_cache创建一个名为kmem_cache的缓存.并添加到slab_caches链中.

https://github.com/novelinux/linux-4.x.y/tree/master/mm/slab_common.c/create_boot_cache.md

create_kmalloc_cache
----------------------------------------

```
    /*
     * Initialize the caches that provide memory for the  kmem_cache_node
     * structures first.  Without this, further allocations will bug.
     */
    kmalloc_caches[INDEX_NODE] = create_kmalloc_cache("kmalloc-node",
                kmalloc_size(INDEX_NODE), ARCH_KMALLOC_FLAGS);
    slab_state = PARTIAL_NODE;
    setup_kmalloc_cache_index_table();

    slab_early_init = 0;

    /* 5) Replace the bootstrap kmem_cache_node */
    {
        int nid;

        for_each_online_node(nid) {
            init_list(kmem_cache, &init_kmem_cache_node[CACHE_CACHE + nid], nid);

            init_list(kmalloc_caches[INDEX_NODE],
                      &init_kmem_cache_node[SIZE_NODE + nid], nid);
        }
    }
```

创建一个kmalloc-node缓存，并添加到slab_caches中去.

https://github.com/novelinux/linux-4.x.y/tree/master/mm/slab_common.c/create_kmalloc_cache.md

create_kmalloc_caches
----------------------------------------

```
    create_kmalloc_caches(ARCH_KMALLOC_FLAGS);
}
```

https://github.com/novelinux/linux-4.x.y/tree/master/mm/slab_common.c/create_kmalloc_caches.md
