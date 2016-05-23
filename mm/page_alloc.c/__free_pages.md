__free_pages
========================================

__free_pages是一个基础函数，用于实现内核API中所有涉及内存释放的函数。

Arguments
----------------------------------------

path: mm/page_alloc.c
```
void __free_pages(struct page *page, unsigned int order)
{
```

free_hot_cold_page
----------------------------------------

__free_pages首先判断所需释放的内存是单页还是较大的内存块？如果释放单页，则不还给伙伴系统，
而是置于per-CPU缓存中，对很可能出现在CPU高速缓存的页，则放置到热页的列表中。出于该目的，
内核接下来调用free_hot_cold_page。

```
    if (put_page_testzero(page)) {
        if (order == 0)
            free_hot_cold_page(page, false);
```

https://github.com/novelinux/linux-4.x.y/tree/master/mm/page_alloc.c/free_hot_cold_page.md

__free_pages_ok
----------------------------------------

如果释放多个页，那么__free_pages将工作委托给__free_pages_ok.

```
        else
            __free_pages_ok(page, order);
    }
}

EXPORT_SYMBOL(__free_pages);
```

https://github.com/novelinux/linux-4.x.y/tree/master/mm/page_alloc.c/__free_pages_ok.md
