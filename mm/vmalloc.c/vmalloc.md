vmalloc
========================================

vmalloc发起对不连续的内存区的分配操作。该函数只是一个前端，为__vmalloc_node_flags提供适当的参数.

Code Flow
----------------------------------------

```
vmalloc
 |
 +-> __vmalloc_node_flags
     |
     +-> __vmalloc_node <-----------------+
         |                                |
         +-> __vmalloc_node_range         |
             |                            |
             +-> __get_vm_area_node       |
             |   |                        |
             |   +-> kzalloc_node         |
             |   |                        |
             |   +-> alloc_vmap_area      |
             |   |                        |
             |   +-> setup_vmalloc_vm     |
             |                            |
             +-> __vmalloc_area_node      |
                 |                        |
                 +------------------------+-> kmalloc_node
                 |
                 +-> alloc_page(s_node)
                 |
                 +-> map_vm_area
```

vmalloc
----------------------------------------

在调用时，vmalloc将gfp_mask设置为GFP_KERNEL | __GFP_HIGHMEM，内核通过该参数指示内存管理子系统
尽可能从ZONE_HIGHMEM内存域分配页帧。理由已经在上文给出：低端内存域的页帧更为宝贵，因此不应该
浪费到vmalloc的分配中，在此使用高端内存域的页帧完全可以满足要求。

内存取自伙伴系统，而gfp_mask设置为GFP_KERNEL |__GFP_HIGHMEM，因此内核指示内存管理子系统尽可能从
ZONE_HIGHMEM分配页帧。其原因我们已经知道。

从伙伴系统分配内存时，是逐页分配，而不是一次分配一大块。这是vmalloc的一个关键方面。
如果可以确信能够分配连续内存区，那么就没有必要使用vmalloc。毕竟该函数的所有目的就在于分配大的
内存块，尽管因为内存碎片的缘故，内存块中的页帧可能不是连续的。将分配单位拆分得尽可能小（换句话说，
以页为单位），可以确保在物理内存有严重碎片的情况下，vmalloc仍然可以工作。

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

__vmalloc_node_flags
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/mm/vmalloc.c/__vmalloc_node_flags.md
