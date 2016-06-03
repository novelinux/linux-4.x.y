cache_flusharray
========================================

Arguments
-----------------------------------------

path: mm/slab.c
```
static void cache_flusharray(struct kmem_cache *cachep, struct array_cache *ac)
{
    int batchcount;
    struct kmem_cache_node *n;
    int node = numa_mem_id();
    LIST_HEAD(list);

    batchcount = ac->batchcount;
#if DEBUG
    BUG_ON(!batchcount || batchcount > ac->avail);
#endif
    check_irq_off();
    n = get_node(cachep, node);
    spin_lock(&n->list_lock);
    if (n->shared) {
        struct array_cache *shared_array = n->shared;
        int max = shared_array->limit - shared_array->avail;
        if (max) {
            if (batchcount > max)
                batchcount = max;
            memcpy(&(shared_array->entry[shared_array->avail]),
                   ac->entry, sizeof(void *) * batchcount);
            shared_array->avail += batchcount;
            goto free_done;
        }
    }
```

free_block
----------------------------------------

该函数又调用了free_block，将对象从缓存移动到原来的slab，并将剩余的对象向数组起始处移动。

例如，如果缓存中有30个对象的空间，而batchcount为15，则位置0到14的对象将移回slab。剩余编号
15到29的对象则在缓存中向上移动，现在占据位置0到14。将对象从缓存移回到slab是有益的，因此仔细
考察一下free_block是值得的。该函数所需的参数是缓存的kmem_cache_t实例、指向缓存中对象指针数组
的指针、表示数组中对象数目的整数和内存所属的结点。该函数在更新缓存数据结构中未使用对象的数目
之后，遍历objpp中的所有对象。

```
    free_block(cachep, ac->entry, batchcount, node, &list);
free_done:
#if STATS
    {
        int i = 0;
        struct list_head *p;

        p = n->slabs_free.next;
        while (p != &(n->slabs_free)) {
            struct page *page;

            page = list_entry(p, struct page, lru);
            BUG_ON(page->active);

            i++;
            p = p->next;
        }
        STATS_SET_FREEABLE(cachep, i);
    }
#endif
    spin_unlock(&n->list_lock);
    slabs_destroy(cachep, &list);
    ac->avail -= batchcount;
    memmove(ac->entry, &(ac->entry[batchcount]), sizeof(void *)*ac->avail);
}
```

https://github.com/novelinux/linux-4.x.y/blob/master/mm/slab.c/free_block.md
