__free_one_page
========================================

该函数是内存释放功能的基础。相关的内存区被添加到伙伴系统中适当的free_area列表。在释放伙伴对时，
该函数将其合并为一个连续内存区，放置到高一阶的free_area列表中。如果还能合并一个进一步的伙伴对，
那么也进行合并，转移到更高阶的列表。该过程会一直重复下去，直至所有可能的伙伴对都已经合并，并将
改变尽可能向上传播。

但内核如何知道一个伙伴对的两个部分都位于空闲页的列表中. 为将内存块放回伙伴系统，内核必须计算
潜在伙伴的地址，以及在有可能合并的情况下合并后内存块的索引。

Comments
----------------------------------------

path: mm/page_alloc.c
```
/*
 * Freeing function for a buddy system allocator.
 *
 * The concept of a buddy system is to maintain direct-mapped table
 * (containing bit values) for memory blocks of various "orders".
 * The bottom level table contains the map for the smallest allocatable
 * units of memory (here, pages), and each level above it describes
 * pairs of units from the levels below, hence, "buddies".
 * At a high level, all that happens here is marking the table entry
 * at the bottom level available, and propagating the changes upward
 * as necessary, plus some accounting needed to play nicely with other
 * parts of the VM system.
 * At each level, we keep a list of pages, which are heads of continuous
 * free pages of length of (1 << order) and marked with _mapcount
 * PAGE_BUDDY_MAPCOUNT_VALUE. Page's order is recorded in page_private(page)
 * field.
 * So when we are allocating or freeing one, we can derive the state of the
 * other.  That is, if we allocate a small block, and both were
 * free, the remainder of the region must be split into blocks.
 * If a block is freed, and its buddy is also free, then this
 * triggers coalescing into a block of larger size.
 *
 * -- nyc
 */
```

Arguments
----------------------------------------

```
static inline void __free_one_page(struct page *page,
        unsigned long pfn,
        struct zone *zone, unsigned int order,
        int migratetype)
{
    unsigned long page_idx;
    unsigned long combined_idx;
    unsigned long uninitialized_var(buddy_idx);
    struct page *buddy;
    int max_order = MAX_ORDER;

    VM_BUG_ON(!zone_is_initialized(zone));
    VM_BUG_ON_PAGE(page->flags & PAGE_FLAGS_CHECK_AT_PREP, page);

    VM_BUG_ON(migratetype == -1);
    if (is_migrate_isolate(migratetype)) {
        /*
         * We restrict max order of merging to prevent merge
         * between freepages on isolate pageblock and normal
         * pageblock. Without this, pageblock isolation
         * could cause incorrect freepage accounting.
         */
        max_order = min(MAX_ORDER, pageblock_order + 1);
    } else {
        __mod_zone_freepage_state(zone, 1 << order, migratetype);
    }

    page_idx = pfn & ((1 << max_order) - 1);

    VM_BUG_ON_PAGE(page_idx & ((1 << order) - 1), page);
    VM_BUG_ON_PAGE(bad_range(zone, page), page);
```

Free
----------------------------------------

试图释放分配阶为order的一个内存块。有可能不只当前内存块能够与其直接伙伴合并，而且高阶的伙伴也
可以合并，因此内核需要找到可能的最大分配阶。

```
    while (order < max_order - 1) {
        buddy_idx = __find_buddy_index(page_idx, order);
        buddy = page + (buddy_idx - page_idx);
        if (!page_is_buddy(page, buddy, order))
            break;
        /*
         * Our buddy is free or it is CONFIG_DEBUG_PAGEALLOC guard page,
         * merge with it and move up one order.
         */
        if (page_is_guard(buddy)) {
            clear_page_guard(zone, buddy, order, migratetype);
        } else {
            list_del(&buddy->lru);
            zone->free_area[order].nr_free--;
            rmv_page_order(buddy);
        }
        combined_idx = buddy_idx & page_idx;
        page = page + (combined_idx - page_idx);
        page_idx = combined_idx;
        order++;
    }
```

### Example

通过例子，可以更透彻地理解代码的行为。假定释放一个0阶内存块，即一页，该页的索引为10。

https://github.com/novelinux/linux-4.x.y/tree/master/mm/page_alloc.c/res/__free_one_page_1.jpg

上图给出了所需的计算，而下图以可视化形式说明了过程的各个步骤。

https://github.com/novelinux/linux-4.x.y/tree/master/mm/page_alloc.c/res/__free_one_page_2.jpg

我们假定页10是合并两个3阶伙伴时最后缺失的环节，有了该页，即可形成一个4阶的内存块。

1.第一遍循环找到页10的伙伴页11。由于需要的不是伙伴的页号，而是指向对应page实例的指针，
  buddy_idx - page_idx就派上用场了。该值表示当前页与伙伴之间的差，page指针加上该值，
  即得到伙伴的page实例。

2.page_is_buddy需要该指针来检查伙伴是否是空闲的。根据图__free_one_page_2.jpg所示，恰好如此，
  因此可以合并这两个伙伴。这需要将页11临时从伙伴系统移除，因为要将其重新合并到一个更大的
  内存块中。page实例从空闲列表移除，而rmv_page_order负责清除PG_buddy标志和private数据。

3.接下来的代码计算合并内存块的索引，得结果为10，因为这个2页的伙伴内存块从该页号开始。在每个循环
  步骤结束时，page指针都指向新的伙伴内存块中的第1页，但对应的page实例就无需修改了。

下一遍循环的工作类似，但这一次order = 1。也就是说，内核试图合并两个2页的伙伴，得到一个4页的内存块。
页范围［10, 11］的伙伴起始于页号8，因此差值buddy_index -page_index是负的。事实上，伙伴也可能出现
在当前内存块的左侧，这是无法阻止的。合并后的内存块索引为8，因此在page_is_buddy确认新伙伴的所有
页（即页8和9）都包含在伙伴系统中之后，需要相应地更新page指针。该循环一直持续到分配阶4。此时，
内存块无法与伙伴合并，如图所示，其伙伴不是空闲的。因此，page_is_buddy不会允许合并这两个内存块，
循环将退出。

最后，需要将包含2=16页的内存块放置到伙伴系统的空闲列表上。这并不很复杂：

```
    set_page_order(page, order);

    /*
     * If this is not the largest possible page, check if the buddy
     * of the next-highest order is free. If it is, it's possible
     * that pages are being freed that will coalesce soon. In case,
     * that is happening, add the free page to the tail of the list
     * so it's less likely to be used soon and more likely to be merged
     * as a higher order page
     */
    if ((order < MAX_ORDER-2) && pfn_valid_within(page_to_pfn(buddy))) {
        struct page *higher_page, *higher_buddy;
        combined_idx = buddy_idx & page_idx;
        higher_page = page + (combined_idx - page_idx);
        buddy_idx = __find_buddy_index(combined_idx, order + 1);
        higher_buddy = higher_page + (buddy_idx - combined_idx);
        if (page_is_buddy(higher_page, higher_buddy, order + 1)) {
            list_add_tail(&page->lru,
                &zone->free_area[order].free_list[migratetype]);
            goto out;
        }
    }

    list_add(&page->lru, &zone->free_area[order].free_list[migratetype]);
out:
    zone->free_area[order].nr_free++;
}
```
