__free_pages_ok
========================================

Arguments
----------------------------------------

path: mm/page_alloc.c
```
static void __free_pages_ok(struct page *page, unsigned int order)
{
    unsigned long flags;
    int migratetype;
    unsigned long pfn = page_to_pfn(page);

    if (!free_pages_prepare(page, order))
        return;

    migratetype = get_pfnblock_migratetype(page, pfn);
    local_irq_save(flags);
    __count_vm_events(PGFREE, 1 << order);
```

free_one_page
----------------------------------------

__free_one_page与其名称不同，该函数不仅处理单页的释放，也处理复合页释放。

```
    free_one_page(page_zone(page), page, pfn, order, migratetype);
    local_irq_restore(flags);
}
```

https://github.com/novelinux/linux-4.x.y/tree/master/mm/page_alloc.c/free_one_page.md
