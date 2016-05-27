__vmalloc_node_range
========================================

Arguments
----------------------------------------

path: mm/vmalloc.c
```
/**
 *    __vmalloc_node_range  -  allocate virtually contiguous memory
 *    @size:        allocation size
 *    @align:        desired alignment
 *    @start:        vm area range start
 *    @end:        vm area range end
 *    @gfp_mask:    flags for the page level allocator
 *    @prot:        protection mask for the allocated pages
 *    @vm_flags:    additional vm area flags (e.g. %VM_NO_GUARD)
 *    @node:        node to use for allocation or NUMA_NO_NODE
 *    @caller:    caller's return address
 *
 *    Allocate enough pages to cover @size from the page level
 *    allocator with @gfp_mask flags.  Map them into contiguous
 *    kernel virtual space, using a pagetable protection of @prot.
 */
void *__vmalloc_node_range(unsigned long size, unsigned long align,
            unsigned long start, unsigned long end, gfp_t gfp_mask,
            pgprot_t prot, unsigned long vm_flags, int node,
            const void *caller)
{
    struct vm_struct *area;
    void *addr;
    unsigned long real_size = size;

    size = PAGE_ALIGN(size);
    if (!size || (size >> PAGE_SHIFT) > totalram_pages)
        goto fail;
```

__get_vm_area_node
----------------------------------------

```
    area = __get_vm_area_node(size, align, VM_ALLOC | VM_UNINITIALIZED |
                vm_flags, start, end, node, gfp_mask, caller);
    if (!area)
        goto fail;
```

https://github.com/novelinux/linux-4.x.y/tree/master/mm/vmalloc.c/__get_vm_area_node.md

__vmalloc_area_node
----------------------------------------

```
    addr = __vmalloc_area_node(area, gfp_mask, prot, node);
    if (!addr)
        return NULL;

    /*
     * In this function, newly allocated vm_struct has VM_UNINITIALIZED
     * flag. It means that vm_struct is not fully initialized.
     * Now, it is fully initialized, so remove this flag here.
     */
    clear_vm_uninitialized_flag(area);

    /*
     * A ref_count = 2 is needed because vm_struct allocated in
     * __get_vm_area_node() contains a reference to the virtual address of
     * the vmalloc'ed block.
     */
    kmemleak_alloc(addr, real_size, 2, gfp_mask);

    return addr;

fail:
    warn_alloc_failed(gfp_mask, 0,
              "vmalloc: allocation failure: %lu bytes\n",
              real_size);
    return NULL;
}
```
