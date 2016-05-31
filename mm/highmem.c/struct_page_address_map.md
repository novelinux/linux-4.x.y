struct page_address_map
========================================

path: mm/highmem.c
```
/*
 * Describes one page->virtual association
 */
struct page_address_map {
    struct page *page;
    void *virtual;
    struct list_head list;
};

static struct page_address_map page_address_maps[LAST_PKMAP];
```

该结构用于建立page->virtual的映射（该结构由此得名）。page是一个指向全局mem_map数组中的page
实例的指针，virtual指定了该页在内核虚拟地址空间中分配的位置。为便于组织，映射保存在散列表中，
结构中的链表元素用于建立溢出链表，以处理散列碰撞。