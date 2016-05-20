__free_pages_bootmem
========================================

path: mm/page_alloc.c
```
void __init __free_pages_bootmem(struct page *page, unsigned long pfn,
                            unsigned int order)
{
    if (early_page_uninitialised(pfn))
        return;
    return __free_pages_boot_core(page, pfn, order);
}
```

__free_pages_boot_core
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/mm/page_alloc.c/__free_pages_boot_core.md
