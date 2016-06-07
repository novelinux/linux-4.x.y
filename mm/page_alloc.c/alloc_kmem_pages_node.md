alloc_kmem_pages_node
========================================

path: mm/page_alloc.c
```
struct page *alloc_kmem_pages_node(int nid, gfp_t gfp_mask, unsigned int order)
{
    struct page *page;

    page = alloc_pages_node(nid, gfp_mask, order);
    if (page && memcg_kmem_charge(page, gfp_mask, order) != 0) {
        __free_pages(page, order);
        page = NULL;
    }
    return page;
}
```

alloc_pages_node
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/gfp.h/alloc_pages_node.md