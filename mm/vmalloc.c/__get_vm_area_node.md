__get_vm_area_node
========================================

根据子区域的长度信息，该函数试图在虚拟的vmalloc空间中找到一个适当的位置。
如果没有指定flags中的VM_NO_GUARD那么各个vmalloc子区域之间需要插入1页(警戒页)
作为安全隙，内核首先适当提高需要分配的内存长度。

Arguments
----------------------------------------

path: mm/vmalloc.c
```
static struct vm_struct *__get_vm_area_node(unsigned long size,
        unsigned long align, unsigned long flags, unsigned long start,
        unsigned long end, int node, gfp_t gfp_mask, const void *caller)
{
    struct vmap_area *va;
    struct vm_struct *area;

    BUG_ON(in_interrupt());
    if (flags & VM_IOREMAP)
        align = 1ul << clamp_t(int, fls_long(size),
                       PAGE_SHIFT, IOREMAP_MAX_ORDER);

    size = PAGE_ALIGN(size);
    if (unlikely(!size))
        return NULL;

    area = kzalloc_node(sizeof(*area), gfp_mask & GFP_RECLAIM_MASK, node);
    if (unlikely(!area))
        return NULL;

    if (!(flags & VM_NO_GUARD))
        size += PAGE_SIZE;
```

alloc_vmap_area
----------------------------------------

```
    va = alloc_vmap_area(size, align, start, end, node, gfp_mask);
    if (IS_ERR(va)) {
        kfree(area);
        return NULL;
    }

    setup_vmalloc_vm(area, va, flags, caller);

    return area;
}
```