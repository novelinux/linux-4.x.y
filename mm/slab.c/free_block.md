free_block
========================================

free_block将对象从缓存移动到原来的slab，并将剩余的对象向数组起始处移动。

例如，如果缓存中有30个对象的空间，而batchcount为15，则位置0到14的对象将移回slab。剩余编号
15到29的对象则在缓存中向上移动，现在占据位置0到14。将对象从缓存移回到slab是有益的，因此仔细
考察一下free_block是值得的。该函数所需的参数是缓存的kmem_cache_t实例、指向缓存中对象指针数组
的指针、表示数组中对象数目的整数和内存所属的结点。该函数在更新缓存数据结构中未使用对象的数目
之后，遍历objpp中的所有对象。

Arguments
----------------------------------------

path: mm/slab.c
```
/*
 * Caller needs to acquire correct kmem_cache_node's list_lock
 * @list: List of detached free slabs should be freed by caller
 */
static void free_block(struct kmem_cache *cachep, void **objpp,
            int nr_objects, int node, struct list_head *list)
{
    int i;
    struct kmem_cache_node *n = get_node(cachep, node);
```

Scan
----------------------------------------

对每个对象必须执行下列操作.

```
    for (i = 0; i < nr_objects; i++) {
        void *objp;
        struct page *page;

        clear_obj_pfmemalloc(&objpp[i]);
        objp = objpp[i];
```

### virt_to_head_page

在确定对象所属的slab之前，首先必须调用virt_to_head_page找到对象所在的页。

```
        page = virt_to_head_page(objp);
        list_del(&page->lru);
        check_spinlock_acquired_node(cachep, node);
```

### slab_put_obj

```
        slab_put_obj(cachep, page, objp, node);
```

https://github.com/novelinux/linux-4.x.y/tree/master/mm/slab.c/slab_put_obj.md

### put

```
        STATS_DEC_ACTIVE(cachep);
        n->free_objects++;

        /* fixup slab chains */
        /* 如果在删除之后，page中的所有对象都是未使用的(page->active == 0)，则将
         * page置于slabs_free链表中。
         */
        if (page->active == 0) {
            if (n->free_objects > n->free_limit) {
                n->free_objects -= cachep->num;
                list_add_tail(&page->lru, list);
            } else {
                list_add(&page->lru, &n->slabs_free);
            }
        } else {
            /* Unconditionally move a slab to the end of the
             * partial list on free - maximum time for the
             * other objects to be freed, too.
             */
            list_add_tail(&page->lru, &n->slabs_partial);
        }
    }
}
```