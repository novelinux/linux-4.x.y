prep_new_page
========================================

prep_new_page对页进行几项检查，确保分配之后分配器处于理想状态。特别地，这意味着在现存的映射中
不能使用该页，也没有设置不正确的标志（如PG_locked或PG_buddy），因为这说明页处于使用中，不应该
放置在空闲列表上。但通常情况下，不应该发生错误，否则就意味着内核在其他地方出现了错误。该函数也
为各个新页设置下列默认标志：

Arguments
----------------------------------------

path: mm/page_alloc.c
```
static int prep_new_page(struct page *page, unsigned int order, gfp_t gfp_flags,
                         int alloc_flags)
{
```

check_new_page
----------------------------------------

```
    int i;

    for (i = 0; i < (1 << order); i++) {
        struct page *p = page + i;
        if (unlikely(check_new_page(p)))
            return 1;
    }
```

----------------------------------------

```
    set_page_private(page, 0);
    set_page_refcounted(page);

    arch_alloc_page(page, order);
    kernel_map_pages(page, 1 << order, 1);
    kasan_alloc_pages(page, order);
```

Check gfp_flags
----------------------------------------

```
    if (gfp_flags & __GFP_ZERO)
        for (i = 0; i < (1 << order); i++)
            clear_highpage(page + i);

    if (order && (gfp_flags & __GFP_COMP))
        prep_compound_page(page, order);

    set_page_owner(page, order, gfp_flags);

    /*
     * page is set pfmemalloc when ALLOC_NO_WATERMARKS was necessary to
     * allocate the page. The expectation is that the caller is taking
     * steps that will free more memory. The caller should avoid the page
     * being used for !PFMEMALLOC purposes.
     */
    if (alloc_flags & ALLOC_NO_WATERMARKS)
        set_page_pfmemalloc(page);
    else
        clear_page_pfmemalloc(page);

    return 0;
}
```

* 如果设置了__GFP_ZERO，prep_zero_page使用一个特定于体系结构的高效函数将页填充字节0;
* 如果设置了__GFP_COMP并请求了多个页，内核必须将这些页组成复合页（compound page）。
  第一个页称作首页（head page），而所有其余各页称作尾页（tail page）。复合页的结构如图所示:

https://github.com/novelinux/linux-4.x.y/tree/master/mm/page_alloc.c/res/PG_compound.jpg

复合页通过PG_compound标志位识别。组成复合页的所有页的page实例的private成员，包括首页在内，
都指向首页。此外，内核需要存储一些信息，描述如何释放复合页。这包括一个释放页的函数，以及
组成复合页的页数。第一个尾页的LRU链表元素因此被滥用：指向析构函数的指针保存在lru.next，
而分配阶保存在lru.prev。请注意，lru成员无法用于这用途，因为如果将复合页连接到内核链表中，
是需要该成员的。为什么需要该信息？内核可能合并多个相邻的物理内存页，形成所谓的巨型TLB页。
在用户层应用程序处理大块数据时，许多处理器允许使用巨型TLB页，将数据保存在内存中。由于巨型
TLB页比普通页大，这降低了保存在地址转换后备缓冲器（TLB）中的信息的数量，因而又降低了TLB缓存
失效的概率，从而加速了内存访问。但与多个普通页组成的复合页相比，巨型TLB页需要用不同的方法释放，
因而需要一个显式的析构器函数。free_compound_pages用于该目的。本质上，在释放复合页时，该函数
通过lru.prev确定页的分配阶，并依次释放各页。辅助函数prep_compound_page用于设置以上描述的结构。