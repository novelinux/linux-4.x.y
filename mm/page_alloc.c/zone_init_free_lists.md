zone_init_free_lists
========================================

空闲列表是在zone_init_free_lists中初始化的.

path: mm/page_alloc.c
```
static void __meminit zone_init_free_lists(struct zone *zone)
{
    unsigned int order, t;
    for_each_migratetype_order(order, t) {
        INIT_LIST_HEAD(&zone->free_area[order].free_list[t]);
        zone->free_area[order].nr_free = 0;
    }
}
```