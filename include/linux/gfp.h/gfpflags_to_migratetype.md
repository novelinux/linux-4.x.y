gfpflags_to_migratetype
========================================

内核如何知道给定的分配内存属于何种迁移类型？有关各个内存分配的细节都通过分配掩码指定。内核提供了
两个标志，分别用于表示分配的内存是可移动的（__GFP_MOVABLE）或可回收的（__GFP_RECLAIMABLE）。如果
这些标志都没有设置，则分配的内存假定为不可移动的。下列辅助函数可用于转换分配标志及对应的迁移类型：

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