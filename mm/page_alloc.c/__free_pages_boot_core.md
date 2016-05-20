__free_pages_boot_core
========================================

path: mm/page_alloc.c
```
static void __init __free_pages_boot_core(struct page *page,
                    unsigned long pfn, unsigned int order)
{
    unsigned int nr_pages = 1 << order;
    struct page *p = page;
    unsigned int loop;

    prefetchw(p);
    for (loop = 0; loop < (nr_pages - 1); loop++, p++) {
        prefetchw(p + 1);
        __ClearPageReserved(p);
        set_page_count(p, 0);
    }
    __ClearPageReserved(p);
    set_page_count(p, 0);

    page_zone(page)->managed_pages += nr_pages;
    set_page_refcounted(page);
```

__free_pages
----------------------------------------

```
    __free_pages(page, order);
}
```

https://github.com/novelinux/linux-4.x.y/blob/master/mm/page_alloc.c/__free_pages.md
