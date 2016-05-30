alloc_vmap_area
========================================

Variable
----------------------------------------

```
/* Export for kexec only */
LIST_HEAD(vmap_area_list);
static struct rb_root vmap_area_root = RB_ROOT;

/* The vmap cache globals are protected by vmap_area_lock */
static struct rb_node *free_vmap_cache;
static unsigned long cached_hole_size;
static unsigned long cached_vstart;
static unsigned long cached_align;
```

Arguments
----------------------------------------

path: mm/vmalloc.c
```
/*
 * Allocate a region of KVA of the specified size and alignment, within the
 * vstart and vend.
 */
static struct vmap_area *alloc_vmap_area(unsigned long size,
                unsigned long align,
                unsigned long vstart, unsigned long vend,
                int node, gfp_t gfp_mask)
{
    struct vmap_area *va;
    struct rb_node *n;
    unsigned long addr;
    int purged = 0;
    struct vmap_area *first;

    BUG_ON(!size);
    BUG_ON(offset_in_page(size));
    BUG_ON(!is_power_of_2(align));
```

kmalloc_node
----------------------------------------

```
    va = kmalloc_node(sizeof(struct vmap_area),
            gfp_mask & GFP_RECLAIM_MASK, node);
    if (unlikely(!va))
        return ERR_PTR(-ENOMEM);

    /*
     * Only scan the relevant parts containing pointers to other objects
     * to avoid false negatives.
     */
    kmemleak_scan_area(&va->rb_node, SIZE_MAX, gfp_mask & GFP_RECLAIM_MASK);
```

retry
----------------------------------------

```
retry:
    spin_lock(&vmap_area_lock);
    /*
     * Invalidate cache if we have more permissive parameters.
     * cached_hole_size notes the largest hole noticed _below_
     * the vmap_area cached in free_vmap_cache: if size fits
     * into that hole, we want to scan from vstart to reuse
     * the hole instead of allocating above free_vmap_cache.
     * Note that __free_vmap_area may update free_vmap_cache
     * without updating cached_hole_size or cached_align.
     */
    if (!free_vmap_cache ||
            size < cached_hole_size ||
            vstart < cached_vstart ||
            align < cached_align) {
nocache:
        cached_hole_size = 0;
        free_vmap_cache = NULL;
    }
    /* record if we encounter less permissive parameters */
    cached_vstart = vstart;
    cached_align = align;
```

### free_vmap_cache

从free_vmap_cache中寻找合适的struct vmap_area结构保存到first中.

```
    /* find starting point for our search */
    if (free_vmap_cache) {
        first = rb_entry(free_vmap_cache, struct vmap_area, rb_node);
        addr = ALIGN(first->va_end, align);
        if (addr < vstart)
            goto nocache;
        if (addr + size < addr)
            goto overflow;
```

### vmap_area_root

从vmap_area_root中寻找合适的struct vmap_area结构保存到first中.

```
    } else {
        addr = ALIGN(vstart, align);
        if (addr + size < addr)
            goto overflow;

        n = vmap_area_root.rb_node;
        first = NULL;

        while (n) {
            struct vmap_area *tmp;
            tmp = rb_entry(n, struct vmap_area, rb_node);
            if (tmp->va_end >= addr) {
                first = tmp;
                if (tmp->va_start <= addr)
                    break;
                n = n->rb_left;
            } else
                n = n->rb_right;
        }

        if (!first)
            goto found;
    }
```

### first

```
    /* from the starting point, walk areas until a suitable hole is found */
    while (addr + size > first->va_start && addr + size <= vend) {
        if (addr + cached_hole_size < first->va_start)
            cached_hole_size = first->va_start - addr;
        addr = ALIGN(first->va_end, align);
        if (addr + size < addr)
            goto overflow;

        if (list_is_last(&first->list, &vmap_area_list))
            goto found;

        first = list_next_entry(first, list);
    }
```

### found

寻找到合适的vmap_area之后调用__insert_vmap_area插入到vmap_area_root和保存到free_vmap_cache中去.

```
found:
    if (addr + size > vend)
        goto overflow;

    va->va_start = addr;
    va->va_end = addr + size;
    va->flags = 0;
    __insert_vmap_area(va);
    free_vmap_cache = &va->rb_node;
    spin_unlock(&vmap_area_lock);

    BUG_ON(!IS_ALIGNED(va->va_start, align));
    BUG_ON(va->va_start < vstart);
    BUG_ON(va->va_end > vend);

    return va;
```

https://github.com/novelinux/linux-4.x.y/tree/master/mm/vmalloc.c/__insert_vmap_area.md

### overflow

```
overflow:
    spin_unlock(&vmap_area_lock);
    if (!purged) {
        purge_vmap_area_lazy();
        purged = 1;
        goto retry;
    }
    if (printk_ratelimit())
        pr_warn("vmap allocation for size %lu failed: "
            "use vmalloc=<size> to increase size.\n", size);
    kfree(va);
    return ERR_PTR(-EBUSY);
}
```