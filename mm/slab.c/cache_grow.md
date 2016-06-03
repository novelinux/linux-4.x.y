cache_grow
========================================

Arguments
----------------------------------------

path: mm/slab.c
```
/*
 * Grow (by 1) the number of slabs within a cache.  This is called by
 * kmem_cache_alloc() when there are no active objs left in a cache.
 */
static int cache_grow(struct kmem_cache *cachep,
        gfp_t flags, int nodeid, struct page *page)
{
    void *freelist;
    size_t offset;
    gfp_t local_flags;
    struct kmem_cache_node *n;
```

get_node
----------------------------------------

```
    /*
     * Be lazy and only check for valid flags here,  keeping it out of the
     * critical path in kmem_cache_alloc().
     */
    if (unlikely(flags & GFP_SLAB_BUG_MASK)) {
        pr_emerg("gfp: %u\n", flags & GFP_SLAB_BUG_MASK);
        BUG();
    }
    local_flags = flags & (GFP_CONSTRAINT_MASK|GFP_RECLAIM_MASK);

    /* Take the node list lock to change the colour_next on this node */
    check_irq_off();
    n = get_node(cachep, nodeid);
    spin_lock(&n->list_lock);
```

Get Colour
----------------------------------------

```
    /* Get colour for the slab, and cal the next value. */
    /* 如果达到了颜色的最大数目，则内核重新开始从0计数，这自动导致了零偏移。*/
    offset = n->colour_next;
    n->colour_next++;
    if (n->colour_next >= cachep->colour)
        n->colour_next = 0;
    spin_unlock(&n->list_lock);

    offset *= cachep->colour_off;

    if (local_flags & __GFP_WAIT)
        local_irq_enable();
```

kmem_flagcheck
----------------------------------------

```
    /*
     * The test for missing atomic flag is performed here, rather than
     * the more obvious place, simply to reduce the critical path length
     * in kmem_cache_alloc(). If a caller is seriously mis-behaving they
     * will eventually be caught here (where it matters).
     */
    kmem_flagcheck(cachep, flags);
```

kmem_getpages
----------------------------------------

```
    /*
     * Get mem for the objs.  Attempt to allocate a physical page from
     * 'nodeid'.
     */
    if (!page)
        page = kmem_getpages(cachep, local_flags, nodeid);
    if (!page)
        goto failed;
```

所需的内存空间是使用kmem_getpages辅助函数从伙伴系统逐页分配的。该函数唯一的目的就是用
适当的参数调用alloc_pages_node函数。各个页都设置了PG_slab标志位，表示该页属于slab分配器。
在一个slab用于满足短期或可回收分配时，则将标志__GFP_RECLAIMABLE传递到伙伴系统。
我们知道重要的是从适当的迁移列表分配页。

alloc_slabmgmt
----------------------------------------

```
    /* Get slab management. */
    freelist = alloc_slabmgmt(cachep, page, offset,
            local_flags & ~GFP_CONSTRAINT_MASK, nodeid);
    if (!freelist)
        goto opps1;
```

如果slab头存储在slab之外，则调用相关的alloc_slabmgmt函数分配所需空间。否则，相应的空间已经在
slab中分配。在两种情况下，都必须用适当的值初始化slab数据结构的colouroff、s_mem和inuse成员。

slab_map_pages
----------------------------------------

```
    slab_map_pages(cachep, page, freelist);
```

接下来，内核调用slab_map_pages创建slab的各页与slab或缓存之间的关联。该函数遍历新分配的所有
page实例，分别调用page_set_cache和page_set_slab。

cache_init_objs
----------------------------------------

```
    cache_init_objs(cachep, page);

    if (local_flags & __GFP_WAIT)
        local_irq_disable();
    check_irq_off();
    spin_lock(&n->list_lock);

    /* Make slab active. */
    list_add_tail(&page->lru, &(n->slabs_free));
    STATS_INC_GROWN(cachep);
    n->free_objects += cachep->num;
    spin_unlock(&n->list_lock);
    return 1;
opps1:
    kmem_freepages(cachep, page);
failed:
    if (local_flags & __GFP_WAIT)
        local_irq_disable();
    return 0;
}
```

cache_init_objs调用各个对象的构造器函数（假如有的话），初始化新slab中的对象。因为内核只有很少
一部分使用了该选项，这方面通常没什么可做的。slab的kmem_bufctl数组也会初始化，在数组位置i存储
i+1：因为slab至今完全未使用，下一个空闲的对象总是下一个对象。根据惯例，最后一个数组元素的值为
BUFCTL_END。现在slab已经完全初始化，可以添加到缓存的slabs_free链表。新产生的对象的数目也加到
缓存中空闲对象的数目上（cachep->free_objects）。
