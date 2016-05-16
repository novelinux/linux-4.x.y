gfpflags_to_migratetype
========================================

如果停用了页面迁移特性，则所有的页都是不可移动的。否则，该函数的返回值可以直接用作
free_area.free_list的数组索引。

path: include/linux/gfp.h
```
/* Convert GFP flags to their corresponding migrate type */
static inline int gfpflags_to_migratetype(const gfp_t gfp_flags)
{
        WARN_ON((gfp_flags & GFP_MOVABLE_MASK) == GFP_MOVABLE_MASK);

        if (unlikely(page_group_by_mobility_disabled))
           return MIGRATE_UNMOVABLE;

        /* Group based on mobility */
        return (((gfp_flags & __GFP_MOVABLE) != 0) << 1) |
            ((gfp_flags & __GFP_RECLAIMABLE) != 0);
}
```