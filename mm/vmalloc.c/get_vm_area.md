get_vm_area
========================================

内核提供了辅助函数get_vm_area，负责参数准备工作。

path: mm/vmalloc.c
```
/**
 *    get_vm_area  -  reserve a contiguous kernel virtual area
 *    @size:          size of the area
 *    @flags:         %VM_IOREMAP for I/O mappings or VM_ALLOC
 *
 *    Search an area of @size in the kernel virtual mapping area,
 *    and reserved it for out purposes.  Returns the area descriptor
 *    on success or %NULL on failure.
 */
struct vm_struct *get_vm_area(unsigned long size, unsigned long flags)
{
    return __get_vm_area_node(size, 1, flags, VMALLOC_START, VMALLOC_END,
                  NUMA_NO_NODE, GFP_KERNEL,
                  __builtin_return_address(0));
}
```

__get_vm_area_node
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/mm/vmalloc.c/__get_vm_area_node.md
