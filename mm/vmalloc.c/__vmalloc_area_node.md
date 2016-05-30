__vmalloc_area_node
========================================

Arguments
----------------------------------------

path: mm/vmalloc.c
```
static void *__vmalloc_area_node(struct vm_struct *area, gfp_t gfp_mask,
                 pgprot_t prot, int node)
{
    const int order = 0;
    struct page **pages;
    unsigned int nr_pages, array_size, i;
    const gfp_t nested_gfp = (gfp_mask & GFP_RECLAIM_MASK) | __GFP_ZERO;
    const gfp_t alloc_mask = gfp_mask | __GFP_NOWARN;
```

Allocation
----------------------------------------

```
    nr_pages = get_vm_area_size(area) >> PAGE_SHIFT;
    array_size = (nr_pages * sizeof(struct page *));

    area->nr_pages = nr_pages;
    /* Please note that the recursion is strictly bounded. */
    if (array_size > PAGE_SIZE) {
        pages = __vmalloc_node(array_size, 1, nested_gfp|__GFP_HIGHMEM,
                PAGE_KERNEL, node, area->caller);
        area->flags |= VM_VPAGES;
    } else {
        pages = kmalloc_node(array_size, nested_gfp, node);
    }
    area->pages = pages;
    if (!area->pages) {
        remove_vm_area(area->addr);
        kfree(area);
        return NULL;
    }
```

### alloc_page_xxx

如果显式指定了分配页帧的结点，则内核调用alloc_pages_node。否则，使用alloc_page
从当前结点分配页帧。

```
    for (i = 0; i < area->nr_pages; i++) {
        struct page *page;

        if (node == NUMA_NO_NODE)
            page = alloc_page(alloc_mask);
        else
            page = alloc_pages_node(node, alloc_mask, order);

        if (unlikely(!page)) {
            /* Successfully allocated i pages, free them in __vunmap() */
            area->nr_pages = i;
            goto fail;
        }
        area->pages[i] = page;
        if (gfp_mask & __GFP_WAIT)
            cond_resched();
    }
```

map_vm_area
----------------------------------------

内核调用map_vm_area将分散的物理内存页连续映射到虚拟的vmalloc区域。该函数遍历分配的物理内存页，
在各级页目录/页表中分配所需的目录项/表项。

```
    if (map_vm_area(area, prot, pages))
        goto fail;
    return area->addr;

fail:
    warn_alloc_failed(gfp_mask, order,
              "vmalloc: allocation failure, allocated %ld of %ld bytes\n",
              (area->nr_pages*PAGE_SIZE), area->size);
    vfree(area->addr);
    return NULL;
}
```
