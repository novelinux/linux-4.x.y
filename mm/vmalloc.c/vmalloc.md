vmalloc
========================================

vmalloc发起对不连续的内存区的分配操作。该函数只是一个前端，为__vmalloc_node_flags提供适当的参数.

path: mm/vmalloc.c
```
/**
 *    vmalloc  -  allocate virtually contiguous memory
 *    @size:      allocation size
 *    Allocate enough pages to cover @size from the page level
 *    allocator and map them into contiguous kernel virtual space.
 *
 *    For tight control over page level allocator and protection flags
 *    use __vmalloc() instead.
 */
void *vmalloc(unsigned long size)
{
    return __vmalloc_node_flags(size, NUMA_NO_NODE,
                    GFP_KERNEL | __GFP_HIGHMEM);
}
EXPORT_SYMBOL(vmalloc);
```

Code Flow
----------------------------------------

```
    vmalloc
       |
       +
__vmalloc_node_flags
       |
       +
__vmalloc_node
       |
       +
__vmalloc_node_range
       |
       +--> __get_vm_area_node
       |
       +--> __vmalloc_area_node
```

__vmalloc_node_flags
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/mm/vmalloc.c/__vmalloc_node_flags.md

__vmalloc_node
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/mm/vmalloc.c/__vmalloc_node.md

__vmalloc_node_range
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/mm/vmalloc.c/__vmalloc_node_range.md
