__vmalloc_node
========================================

path: mm/vmalloc.c
```
/**
 *    __vmalloc_node  -  allocate virtually contiguous memory
 *    @size:        allocation size
 *    @align:        desired alignment
 *    @gfp_mask:    flags for the page level allocator
 *    @prot:        protection mask for the allocated pages
 *    @node:        node to use for allocation or NUMA_NO_NODE
 *    @caller:    caller's return address
 *
 *    Allocate enough pages to cover @size from the page level
 *    allocator with @gfp_mask flags.  Map them into contiguous
 *    kernel virtual space, using a pagetable protection of @prot.
 */
static void *__vmalloc_node(unsigned long size, unsigned long align,
                gfp_t gfp_mask, pgprot_t prot,
                int node, const void *caller)
{
    return __vmalloc_node_range(size, align, VMALLOC_START, VMALLOC_END,
                gfp_mask, prot, 0, node, caller);
}
```

__vmalloc_node_range
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/mm/vmalloc.c/__vmalloc_node_range.md
