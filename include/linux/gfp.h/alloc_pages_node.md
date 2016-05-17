alloc_pages_node
========================================

path: include/linux/gfp.h
```
/*
 * Allocate pages, preferring the node given as nid. When nid == NUMA_NO_NODE,
 * prefer the current CPU's closest node. Otherwise node must be valid and
 * online.
 */
static inline struct page *alloc_pages_node(int nid, gfp_t gfp_mask,
                                            unsigned int order)
{
    if (nid == NUMA_NO_NODE)
        nid = numa_mem_id();

    return __alloc_pages_node(nid, gfp_mask, order);
}
```

__alloc_pages_node
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/gfp.h/__alloc_pages_node.md
