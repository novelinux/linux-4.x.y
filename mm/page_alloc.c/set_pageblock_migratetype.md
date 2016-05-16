set_pageblock_migratetype
========================================

migratetype参数可以通过gfpflags_to_migratetype辅助函数构建。请注意很重要的一点，页的迁移类型是
预先分配好的，对应的比特位总是可用，与页是否由伙伴系统管理无关。在释放内存时，页必须返回到正确
的迁移链表。这之所以可行，是因为能够从get_pageblock_migratetype获得所需的信息。

path: mm/page_alloc.c
```
void set_pageblock_migratetype(struct page *page, int migratetype)
{
    if (unlikely(page_group_by_mobility_disabled &&
             migratetype < MIGRATE_PCPTYPES))
        migratetype = MIGRATE_UNMOVABLE;

    set_pageblock_flags_group(page, (unsigned long)migratetype,
                    PB_migrate, PB_migrate_end);
}
```