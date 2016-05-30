__vunmap
========================================

Arguments
----------------------------------------

path: mm/vmalloc.c
```
static void __vunmap(const void *addr, int deallocate_pages)
{
    struct vm_struct *area;

    if (!addr)
        return;

    if (WARN(!PAGE_ALIGNED(addr), "Trying to vfree() bad address (%p)\n",
            addr))
        return;
```

* addr: 表示要释放的区域的起始地址;
* deallocate_pages: 指定了是否将与该区域相关的物理内存页返回给伙伴系统。

vfree将后一个参数设置为1，而vunmap设置为0，因为在这种情况下只删除映射，而不将相关的物理内存页
返回给伙伴系统。

remove_vm_area
----------------------------------------

```
    area = remove_vm_area(addr);
    if (unlikely(!area)) {
        WARN(1, KERN_ERR "Trying to vfree() nonexistent vm area (%p)\n",
                addr);
        return;
    }

    debug_check_no_locks_freed(addr, area->size);
    debug_check_no_obj_freed(addr, area->size);
```

deallocate_pages
----------------------------------------

如果__vunmap的参数deallocate_pages设置为1（在vfree中），内核会遍历area->pages的所有元素，即指向
所涉及的物理内存页的page实例的指针。然后对每一项调用__free_page，将页释放到伙伴系统。最后，必须
释放用于管理该内存区的内核数据结构。

```
    if (deallocate_pages) {
        int i;

        for (i = 0; i < area->nr_pages; i++) {
            struct page *page = area->pages[i];

            BUG_ON(!page);
            __free_page(page);
        }

        if (area->flags & VM_VPAGES)
            vfree(area->pages);
        else
            kfree(area->pages);
    }

    kfree(area);
    return;
}
```