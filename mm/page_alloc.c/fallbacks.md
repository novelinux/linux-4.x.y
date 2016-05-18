fallbacks
========================================

如果内核无法满足针对某一给定迁移类型的分配请求，会怎么样？此前已经出现过一个类似的问题，
即特定的NUMA内存域无法满足分配请求时。内核在这种情况下的做法是类似的，提供了一个备用列表，
规定了在指定列表中无法满足分配请求时，接下来应使用哪一种迁移类型.

该数据结构大体上是自明的：在内核想要分配不可移动页时，如果对应链表为空，则后退到可回收页链表，
接下来到可移动页链表，最后到紧急分配链表。

path: mm/page_alloc.c
```
/*
 * This array describes the order lists are fallen back to when
 * the free lists for the desirable migrate type are depleted
 */
static int fallbacks[MIGRATE_TYPES][4] = {
       [MIGRATE_UNMOVABLE]   = { MIGRATE_RECLAIMABLE, MIGRATE_MOVABLE,     MIGRATE_RESERVE },
       [MIGRATE_RECLAIMABLE] = { MIGRATE_UNMOVABLE,   MIGRATE_MOVABLE,     MIGRATE_RESERVE },
       [MIGRATE_MOVABLE]     = { MIGRATE_RECLAIMABLE, MIGRATE_UNMOVABLE,   MIGRATE_RESERVE },
#ifdef CONFIG_CMA
       [MIGRATE_CMA]         = { MIGRATE_RESERVE }, /* Never used */
#endif
        [MIGRATE_RESERVE]     = { MIGRATE_RESERVE }, /* Never used */
#ifdef CONFIG_MEMORY_ISOLATION
       [MIGRATE_ISOLATE]     = { MIGRATE_RESERVE }, /* Never used */
#endif
};
```