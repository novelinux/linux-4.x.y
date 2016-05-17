pageblock_order
========================================

尽管页可移动性分组特性总是编译到内核中，但只有在系统中有足够内存可以分配到多个迁移类型对应的链表时，
才是有意义的。由于每个迁移链表都应该有适当数量的内存，内核需要定义“适当”的概念。这是通过两个全局
变量pageblock_order和pageblock_nr_pages提供的。第一个表示是"large"的一个分配阶，pageblock_nr_pages
则表示该分配阶对应的页数。如果体系结构提供了巨型页机制，则pageblock_order通常定义为巨型页对应的
分配阶：

path: include/linux/pageblock-flags.h
```
#ifdef CONFIG_HUGETLB_PAGE

#ifdef CONFIG_HUGETLB_PAGE_SIZE_VARIABLE

/* Huge page sizes are variable */
extern int pageblock_order;

#else /* CONFIG_HUGETLB_PAGE_SIZE_VARIABLE */

/* Huge pages are a constant size */
#define pageblock_order           HUGETLB_PAGE_ORDER

#endif /* CONFIG_HUGETLB_PAGE_SIZE_VARIABLE */

#else /* CONFIG_HUGETLB_PAGE */

/* If huge pages are not used, group by MAX_ORDER_NR_PAGES */
// 如果体系结构不支持巨型页，则将其定义为第二高的分配阶
#define pageblock_order        (MAX_ORDER-1)

#endif /* CONFIG_HUGETLB_PAGE */

#define pageblock_nr_pages    (1UL << pageblock_order)
```

aries
----------------------------------------

```
# CONFIG_HUGETLB_PAGE is not set
```
