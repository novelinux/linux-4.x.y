__alloc_pages_node
========================================

path: include/linux/gfp.h
```
/*
 * Allocate pages, preferring the node given as nid. The node must be valid and
 * online. For more general interface, see alloc_pages_node().
 */
static inline struct page *
__alloc_pages_node(int nid, gfp_t gfp_mask, unsigned int order)
{
    VM_BUG_ON(nid < 0 || nid >= MAX_NUMNODES);
    VM_WARN_ON(!node_online(nid));

    return __alloc_pages(gfp_mask, order, node_zonelist(nid, gfp_mask));
}
```

node_zonelist
----------------------------------------

node_zonelist函数返回适合gfp_mask的内存域列表.

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/gfp.h/node_zonelist.md

__alloc_pages
----------------------------------------

内核源代码将__alloc_pages称之为“伙伴系统的心脏”，因为它处理的是实质性的内存分配。

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/gfp.h/__alloc_pages.md
