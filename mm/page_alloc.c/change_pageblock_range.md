change_pageblock_range
========================================

我们知道，迁移列表是页迁移方法的基础，该方法用于使内存碎片保持在尽可能低的水平。较低的内存碎片
水平，意味着即使在系统已经运行很长时间后，仍然有较大的连续内存块可以分配。

较大内存块有多大的概念由全局变量pageblock_order给出，该变量定义了大内存块的分配阶:

https://github.com/novelinux/linux-4.x.y/blob/master/include/linux/pageblock-flags.h/pageblock_order.md

如果需要分解来自其他迁移列表的空闲内存块，那么内核必须决定如何处理剩余的页。如果剩余部分
也是一个比较大的内存块，那么将整个内存块都转到当前分配类型对应的迁移列表是有意义的，这样
可以减少碎片。

path: mm/page_alloc.c
```
static void change_pageblock_range(struct page *pageblock_page,
                    int start_order, int migratetype)
{
    int nr_pageblocks = 1 << (start_order - pageblock_order);

    while (nr_pageblocks--) {
        set_pageblock_migratetype(pageblock_page, migratetype);
        pageblock_page += pageblock_nr_pages;
    }
}
```
