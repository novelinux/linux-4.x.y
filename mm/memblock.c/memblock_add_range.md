memblock_add_range
========================================

Arguments
----------------------------------------

path: mm/memblock.c
```
/**
 * memblock_add_range - add new memblock region
 * @type: memblock type to add new region into
 * @base: base address of the new region
 * @size: size of the new region
 * @nid: nid of the new region
 * @flags: flags of the new region
 *
 * Add new memblock region [@base,@base+@size) into @type.  The new region
 * is allowed to overlap with existing ones - overlaps don't affect already
 * existing regions.  @type is guaranteed to be minimal (all neighbouring
 * compatible regions are merged) after the addition.
 *
 * RETURNS:
 * 0 on success, -errno on failure.
 */
int __init_memblock memblock_add_range(struct memblock_type *type,
                phys_addr_t base, phys_addr_t size,
                int nid, unsigned long flags)
{
```

memblock_set_region_node
----------------------------------------

```
    bool insert = false;
    phys_addr_t obase = base;
    // 如下代码获得内存区域的结束位置
    phys_addr_t end = base + memblock_cap_size(base, &size);
    int i, nr_new;

    if (!size)
        return 0;

    /* special case for empty array */
    if (type->regions[0].size == 0) {
        WARN_ON(type->cnt != 1 || type->total_size);
        type->regions[0].base = base;
        type->regions[0].size = size;
        type->regions[0].flags = flags;
        memblock_set_region_node(&type->regions[0], nid);
        type->total_size = size;
        return 0;
    }
```

检查type结构体中是否存在内存区域。如果没有，我们就用给定的值填充新的memory_region，我们就把
新的内存区域添加到memblock_type类型的memblock中。

memblock_insert_region
----------------------------------------

```
repeat:
    /*
     * The following is executed twice.  Once with %false @insert and
     * then with %true.  The first counts the number of regions needed
     * to accomodate the new area.  The second actually inserts them.
     */
    base = obase;
    nr_new = 0;
    // 接下来遍历所有已经存储的内存区域并检查有没有和新的内存区域重叠.
    for (i = 0; i < type->cnt; i++) {
        struct memblock_region *rgn = &type->regions[i];
        phys_addr_t rbase = rgn->base;
        phys_addr_t rend = rbase + rgn->size;

        if (rbase >= end)
            break;
        if (rend <= base)
            continue;
        /*
         * @rgn overlaps.  If it separates the lower part of new
         * area, insert that portion.
         */
        if (rbase > base) {
            nr_new++;
            if (insert)
                memblock_insert_region(type, i++, base,
                               rbase - base, nid,
                               flags);
        }
        /* area below @rend is dealt with, forget about it */
        base = min(rend, end);
    }

    /* insert the remaining portion */
    if (base < end) {
        nr_new++;
        if (insert)
            memblock_insert_region(type, i, base, end - base,
                           nid, flags);
    }
```

把新的内存区域中非重叠的部分作为独立的区域加入到 memblock.

memblock_merge_regions
----------------------------------------

```
    /*
     * If this was the first round, resize array and repeat for actual
     * insertions; otherwise, merge and return.
     */
     // 如果这是第一次循环，我们需要检查新内存区域是否可以放入内存块中并调用memblock_double_array
    if (!insert) {
        while (type->cnt + nr_new > type->max)
            if (memblock_double_array(type, obase, size) < 0)
                return -ENOMEM;
        insert = true;
        goto repeat;
    } else {
        memblock_merge_regions(type);
        return 0;
    }
}
```

合并所有相邻的内存区域.
