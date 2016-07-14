vm_unmapped_area
========================================

path: include/linux/mm.h
```
/*
 * Search for an unmapped address range.
 *
 * We are looking for a range that:
 * - does not intersect with any VMA;
 * - is contained within the [low_limit, high_limit) interval;
 * - is at least the desired size.
 * - satisfies (begin_addr & align_mask) == (align_offset & align_mask)
 */
static inline unsigned long
vm_unmapped_area(struct vm_unmapped_area_info *info)
{
    if (info->flags & VM_UNMAPPED_AREA_TOPDOWN)
        return unmapped_area_topdown(info);
    else
        return unmapped_area(info);
}
```

unmapped_area_topdown
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/mm/mmap.c/unmapped_area_topdown.md
