cache_alloc_refill
========================================

Arguments
----------------------------------------

path: mm/slab.c
```
static void *cache_alloc_refill(struct kmem_cache *cachep, gfp_t flags,
                            bool force_refill)
{
    int batchcount;
    struct kmem_cache_node *n;
    struct array_cache *ac;
    int node;

    check_irq_off();
    node = numa_mem_id();
    if (unlikely(force_refill))
        goto force_grow;
```

retry
----------------------------------------

### cpu_cache_get

```
retry:
    ac = cpu_cache_get(cachep);
    batchcount = ac->batchcount;
    if (!ac->touched && batchcount > BATCHREFILL_LIMIT) {
        /*
         * If there was little recent activity on this cache, then
         * perform only a partial refill.  Otherwise we could generate
         * refill bouncing.
         */
        batchcount = BATCHREFILL_LIMIT;
    }
    n = get_node(cachep, node);

    BUG_ON(ac->avail > 0 || !n);
    spin_lock(&n->list_lock);

    /* See if we can refill from the shared array */
    if (n->shared && transfer_objects(ac, n->shared, batchcount)) {
        n->shared->touched = 1;
        goto alloc_done;
    }
```

https://github.com/novelinux/linux-4.x.y/tree/master/mm/slab.c/cpu_cache_get.md

### Choose List

内核现在必须找到array_cache->batchcount个未使用对象重新填充per-CPU缓存。
选择获取对象的slab链表, 首先是slabs_partial, 然后是slabs_free.

```
    while (batchcount > 0) {
        struct list_head *entry;
        struct page *page;
        /* Get slab alloc is to come from. */
        entry = n->slabs_partial.next;
        if (entry == &n->slabs_partial) {
            n->free_touched = 1;
            entry = n->slabs_free.next;
            if (entry == &n->slabs_free)
                goto must_grow;
        }
```

### ac_put_obj

通过slab_get_obj依次获取所有的对象，直至相应的slab中没有空闲对象为止。将获取到的object
调用函数ac_put_obj加入array_cache的entry中去.

```
        page = list_entry(entry, struct page, lru);
        check_spinlock_acquired(cachep);

        /*
         * The slab was either on partial or free list so
         * there must be at least one object available for
         * allocation.
         */
        BUG_ON(page->active >= cachep->num);

        while (page->active < cachep->num && batchcount--) {
            STATS_INC_ALLOCED(cachep);
            STATS_INC_ACTIVE(cachep);
            STATS_SET_HIGH(cachep);

            ac_put_obj(cachep, ac, slab_get_obj(cachep, page,
                                    node));
        }

        /* move slabp to correct slabp list: */
        /* 将page移动到正确的slab链表： */
        list_del(&page->lru);
        if (page->active == cachep->num)
            list_add(&page->lru, &n->slabs_full);
        else
            list_add(&page->lru, &n->slabs_partial);
    }
```

#### slab_get_obj

https://github.com/novelinux/linux-4.x.y/tree/master/mm/slab.c/slab_get_obj.md

#### ac_put_obj

https://github.com/novelinux/linux-4.x.y/tree/master/mm/slab.c/ac_put_obj.md

### cache_grow

如果扫描了所有的slab仍然没有找到空闲对象，那么必须使用cache_grow扩大缓存。

```
must_grow:
    n->free_objects -= ac->avail;
alloc_done:
    spin_unlock(&n->list_lock);

    if (unlikely(!ac->avail)) {
        int x;
force_grow:
        x = cache_grow(cachep, gfp_exact_node(flags), node, NULL);

        /* cache_grow can reenable interrupts, then ac could change. */
        ac = cpu_cache_get(cachep);
        node = numa_mem_id();

        /* no objects in sight? abort */
        if (!x && (ac->avail == 0 || force_refill))
            return NULL;

        if (!ac->avail)        /* objects refilled by interrupt? */
            goto retry;
    }
    ac->touched = 1;
```

https://github.com/novelinux/linux-4.x.y/tree/master/mm/slab.c/cache_grow.md

ac_get_obj
----------------------------------------

```
    return ac_get_obj(cachep, ac, flags, force_refill);
}
```

https://github.com/novelinux/linux-4.x.y/tree/master/mm/slab.c/ac_get_obj.md
