expand
========================================

如果需要分配的内存块长度小于所选择的连续页范围，即如果因为没有更小的适当内存块可用，
而从较高的分配阶分配了一块内存，那么该内存块必须按照伙伴系统的原理分裂成小的块。
这是通过expand函数完成的。

Arguments
----------------------------------------

path: mm/page_alloc.c
```
/*
 * The order of subdivision here is critical for the IO subsystem.
 * Please do not alter this order without good reasons and regression
 * testing. Specifically, as large blocks of memory are subdivided,
 * the order in which smaller blocks are delivered depends on the order
 * they're subdivided in this function. This is the primary factor
 * influencing the order in which pages are delivered to the IO
 * subsystem according to empirical testing, and this is also justified
 * by considering the behavior of a buddy system containing a single
 * large block of memory acted on by a series of small allocations.
 * This behavior is a critical factor in sglist merging's success.
 *
 * -- nyc
 */
static inline void expand(struct zone *zone, struct page *page,
    int low, int high, struct free_area *area,
    int migratetype)
{
```

该函数使用了一组参数。page、zone、area的语义都很显然。

* index指定了该伙伴对在分配位图中的索引位置;
* low是预期的分配阶;
* high表示内存取自哪个分配阶;
* migratetype表示迁移类型。

Sample
----------------------------------------

```
    unsigned long size = 1 << high;

    while (high > low) {
        area--;
        high--;
        size >>= 1;
        VM_BUG_ON_PAGE(bad_range(zone, &page[size]), &page[size]);

        if (IS_ENABLED(CONFIG_DEBUG_PAGEALLOC) &&
            debug_guardpage_enabled() &&
            high < debug_guardpage_minorder()) {
            /*
             * Mark as guard pages (or page), that will allow to
             * merge back to allocator when buddy will be freed.
             * Corresponding page table entries will not be touched,
             * pages will stay not present in virtual address space
             */
            set_page_guard(zone, &page[size], high, migratetype);
            continue;
        }
        list_add(&page[size].lru, &area->free_list[migratetype]);
        area->nr_free++;
        set_page_order(&page[size], high);
    }
}
```

我们假定以下情形：将要分配一个阶为3的块。内存中没有该长度的块，因此内核选择了一个阶为5的块。
为简明起见，该块位于索引0的位置。因此调用该函数的参数如下:

```
expand(zone, page,index=0,low=3,high=5,area, migratetype)
```

下图给出了详细的拆分内存块的步骤:

https://github.com/novelinux/linux-4.x.y/tree/master/mm/page_alloc.c/res/expand/expand_sample.jpg

* size的值初始化为2^high=2^5=32。分配的内存区已经在__rmqueue中从free_area列表移除，
  因此在上图中用虚线画出。

* 在第一遍循环中，内核切换到低一个分配阶、迁移类型相同的free_area列表，即阶为4。
  类似地，内存区长度降低到16（通过size >> 1计算）。初始内存区的后一半插入到阶为4的
  free_area列表中。伙伴系统只需要内存区第一个page实例，用作管理用途。内存区的长度
  可根据页所在的列表自动推导而得。

* 后一半内存区的地址可通过&page[size]计算。而page指针一直指向最初分配内存区的起始地址，
  并不改变。page指针指向的位置在图中用箭头表示。

* 下一遍循环将剩余16页的后一半放置到对应于size=8的free_area列表上。page指针仍然不动。
  现在剩余的内存区已经是预期的长度，可以将page指针作为结果返回。

从图中可见，显然使用了初始32页内存区的起始8页。所有其余各页都进入到伙伴系统中适当的
free_area列表里。内核总是使用特定于迁移类型的free_area列表，在处理期间不会改变页的迁移类型。

set_page_order
----------------------------------------

循环中各个步骤都调用了set_page_order辅助函数，对于回收到伙伴系统的内存区，该函数将第一个
struct page实例的private标志设置为当前分配阶，并设置页的PG_buddy标志位。该标志表示内存块
由伙伴系统管理。