alloc_pages
========================================

path: include/linux/gfp.h
```
#ifdef CONFIG_NUMA
extern struct page *alloc_pages_current(gfp_t gfp_mask, unsigned order);

static inline struct page *
alloc_pages(gfp_t gfp_mask, unsigned int order)
{
    return alloc_pages_current(gfp_mask, order);
}
...
#else
#define alloc_pages(gfp_mask, order) \
           alloc_pages_node(numa_node_id(), gfp_mask, order)
...
#endif
```

alloc_pages_node
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/gfp.h/alloc_pages_node.md
