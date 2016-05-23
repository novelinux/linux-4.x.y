free_hot_cold_page
========================================

如果free_hot_cold_page判断per-CPU缓存中页的数目超出了pcp->count，则将数量为pcp->batch的一批
内存页还给伙伴系统。该策略称之为惰性合并（lazy coalescing）。如果单页直接返回给伙伴系统，那么
会发生合并，而为了满足后来的分配请求又需要进行拆分。因而惰性合并策略阻止了大量可能白费时间的
合并操作。free_pages_bulk用于将页还给伙伴系统。如果不超出惰性合并的限制，则页只是保存在per-CPU
缓存中。但重要的是将private成员设置为页的迁移类型。根据前文所述，这使得可以从per-CPU缓存分配单页，
并选择正确的迁移类型。

path: mm/page_alloc.c
```
/*
 * Free a 0-order page
 * cold == true ? free a cold page : free a hot page
 */
void free_hot_cold_page(struct page *page, bool cold)
{
    struct zone *zone = page_zone(page);
    struct per_cpu_pages *pcp;
    unsigned long flags;
    unsigned long pfn = page_to_pfn(page);
    int migratetype;

    if (!free_pages_prepare(page, 0))
        return;

    migratetype = get_pfnblock_migratetype(page, pfn);
    set_pcppage_migratetype(page, migratetype);
    local_irq_save(flags);
    __count_vm_event(PGFREE);

    /*
     * We only track unmovable, reclaimable and movable on pcp lists.
     * Free ISOLATE pages back to the allocator because they are being
     * offlined but treat RESERVE as movable pages so we can get those
     * areas back if necessary. Otherwise, we may have to free
     * excessively into the page allocator
     */
    if (migratetype >= MIGRATE_PCPTYPES) {
        if (unlikely(is_migrate_isolate(migratetype))) {
            free_one_page(zone, page, pfn, 0, migratetype);
            goto out;
        }
        migratetype = MIGRATE_MOVABLE;
    }

    pcp = &this_cpu_ptr(zone->pageset)->pcp;
    if (!cold)
        list_add(&page->lru, &pcp->lists[migratetype]);
    else
        list_add_tail(&page->lru, &pcp->lists[migratetype]);
    pcp->count++;
    if (pcp->count >= pcp->high) {
        unsigned long batch = READ_ONCE(pcp->batch);
        free_pcppages_bulk(zone, batch, pcp);
        pcp->count -= batch;
    }

out:
    local_irq_restore(flags);
}
```