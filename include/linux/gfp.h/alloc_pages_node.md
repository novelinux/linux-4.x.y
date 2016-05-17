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
    /* 只执行了一个简单的检查，避免分配过大的内存块。如果指定负的结点ID（不存在），
     * 内核自动地使用当前执行CPU对应的结点ID。
     */
    if (nid == NUMA_NO_NODE)
        nid = numa_mem_id();

    return __alloc_pages_node(nid, gfp_mask, order);
}
```

__alloc_pages_node
----------------------------------------

接下来的工作委托给__alloc_pages，只需传递一组适当的参数。

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/gfp.h/__alloc_pages_node.md
