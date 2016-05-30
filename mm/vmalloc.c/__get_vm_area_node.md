__get_vm_area_node
========================================

根据子区域的长度信息，该函数试图在虚拟的vmalloc空间中找到一个适当的位置。


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
```

kzalloc_node
----------------------------------------

```
    area = kzalloc_node(sizeof(*area), gfp_mask & GFP_RECLAIM_MASK, node);
    if (unlikely(!area))
        return NULL;

    /* 如果没有指定flags中的VM_NO_GUARD那么各个vmalloc子区域之间需要
     * 插入1页(警戒页)作为安全隙，内核首先适当提高需要分配的内存长度。
     */
    if (!(flags & VM_NO_GUARD))
        size += PAGE_SIZE;
```

alloc_vmap_area
----------------------------------------

为struct vmap_area分配内存.

```
    va = alloc_vmap_area(size, align, start, end, node, gfp_mask);
    if (IS_ERR(va)) {
        kfree(area);
        return NULL;
    }
```

https://github.com/novelinux/linux-4.x.y/tree/master/mm/vmalloc.c/alloc_vmap_area.md

setup_vmalloc_vm
----------------------------------------

```
    setup_vmalloc_vm(area, va, flags, caller);

    return area;
}
```

https://github.com/novelinux/linux-4.x.y/tree/master/mm/vmalloc.c/setup_vmalloc_vm.md
