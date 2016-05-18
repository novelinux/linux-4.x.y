buffered_rmqueue
========================================

如果内核找到适当的内存域，具有足够的空闲页可供分配，那么还有两件事情需要完成。

* 首先它必须检查这些页是否是连续的（到目前为止，只知道有许多空闲页）。
* 其次，必须按伙伴系统的方式从free_lists移除这些页，这可能需要分解并重排内存区。

内核将该工作委托给buffered_rmqueue。

https://github.com/novelinux/linux-4.x.y/tree/master/mm/page_alloc.c/res/buffered_rmqueue.jpg

Arguments
----------------------------------------

path: mm/page_alloc.c
```
/*
 * Allocate a page from the given zone. Use pcplists for order-0 allocations.
 */
static inline
struct page *buffered_rmqueue(struct zone *preferred_zone,
            struct zone *zone, unsigned int order,
            gfp_t gfp_flags, int migratetype)
{
    unsigned long flags;
    struct page *page;
```

cold
----------------------------------------

如果分配标志设置了GFP_COLD，那么必须从per-CPU缓存取得冷页，前提是有的话。
根据分配标志确定迁移列表，也是必要的。

```
    bool cold = ((gfp_flags & __GFP_COLD) != 0);
```

order == 0
----------------------------------------

如果只分配一页，内核会进行优化，即分配阶为0的情形，2^0 = 1。该页不是从伙伴系统直接取得，
而是取自per-CPU的页缓存.内核试图借助于per-CPU缓存加速请求的处理。如果缓存为空，
内核可借机检查缓存填充水平。

在针对当前处理器选择了适当的per-CPU列表（热页或冷页列表）之后，调用rmqueue_bulk重新填充缓存。
因为它只是从通常的伙伴系统移除页，然后添加到缓存。

```
    if (likely(order == 0)) {
        struct per_cpu_pages *pcp;
        struct list_head *list;

        local_irq_save(flags);
        pcp = &this_cpu_ptr(zone->pageset)->pcp;
        list = &pcp->lists[migratetype];
        if (list_empty(list)) {
            pcp->count += rmqueue_bulk(zone, 0,
                    pcp->batch, list,
                    migratetype, cold);
            if (unlikely(list_empty(list)))
                goto failed;
        }

        if (cold)
            page = list_entry(list->prev, struct page, lru);
        else
            page = list_entry(list->next, struct page, lru);

        list_del(&page->lru);
        pcp->count--;
```

order > 0
----------------------------------------

如果需要分配多页（由else分支处理），内核调用__rmqueue会从内存域的伙伴列表中选择适当的内存块。
如有必要，该函数会自动分解大块内存，将未用的部分放回列表中。切记，可能有这样的情况：内存域中
有足够空闲页满足分配请求，但页不是连续的。在这种情况下，__rmqueue失败并返回NULL指针。
由于所有失败情形都跳转到标号failed处理，这可以确保内核到达当前点之后，page指向一系列有效的页。

```
    } else {
        if (unlikely(gfp_flags & __GFP_NOFAIL)) {
            /*
             * __GFP_NOFAIL is not to be used in new code.
             *
             * All __GFP_NOFAIL callers should be fixed so that they
             * properly detect and handle allocation failures.
             *
             * We most definitely don't want callers attempting toa
             * allocate greater than order-1 page units with
             * __GFP_NOFAIL.
             */
            WARN_ON_ONCE(order > 1);
        }
        spin_lock_irqsave(&zone->lock, flags);
        page = __rmqueue(zone, order, migratetype);
        spin_unlock(&zone->lock);
        if (!page)
            goto failed;
        __mod_zone_freepage_state(zone, -(1 << order),
                      get_pcppage_migratetype(page));
    }
```


```
    __mod_zone_page_state(zone, NR_ALLOC_BATCH, -(1 << order));
    if (atomic_long_read(&zone->vm_stat[NR_ALLOC_BATCH]) <= 0 &&
        !test_bit(ZONE_FAIR_DEPLETED, &zone->flags))
        set_bit(ZONE_FAIR_DEPLETED, &zone->flags);

    __count_zone_vm_events(PGALLOC, zone, 1 << order);
    zone_statistics(preferred_zone, zone, gfp_flags);
    local_irq_restore(flags);

    VM_BUG_ON_PAGE(bad_range(zone, page), page);
    return page;

failed:
    local_irq_restore(flags);
    return NULL;
}
```