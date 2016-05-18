build_all_zonelists
========================================

在体系结构相关的代码初始化好各节点和内存域相关的数据结构:

https://github.com/novelinux/linux-4.x.y/blob/master/arch/arm/mm/init.c/zone_sizes_init.md

调用build_all_zonelists建立管理结点及其内存域所需的数据结构。有趣的是，该函数可以通过上文引入的
宏和抽象机制实现，而不用考虑具体的NUMA或UMA系统。因为执行的函数实际上有两种形式，所以这样做
是可能的：一种用于NUMA系统，而另一种用于UMA系统。

Arguments
----------------------------------------

path: mm/page_alloc.c
```
/*
 * Called with zonelists_mutex held always
 * unless system_state == SYSTEM_BOOTING.
 */
void __ref build_all_zonelists(pg_data_t *pgdat, struct zone *zone)
{
```

### pgdat

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/mmzone.h/pg_data_t.md

### zone

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/mmzone.h/struct_zone.md

set_zonelist_order
----------------------------------------

设定zonelist的顺序，是按节点还是按管理区排序，只对NUMA有意义.

```
    set_zonelist_order();
```

https://github.com/novelinux/linux-4.x.y/tree/master/mm/page_alloc.c/set_zonelist_order.md

__build_all_zonelists
----------------------------------------

build_all_zonelists中将所有工作都委托给__build_all_zonelists，后者又对系统中的各个NUMA结点分别
调用build_zonelists。

```
    if (system_state == SYSTEM_BOOTING) {
        __build_all_zonelists(NULL);
        mminit_verify_zonelist();
        cpuset_init_current_mems_allowed();
    } else {
#ifdef CONFIG_MEMORY_HOTPLUG
        if (zone)
            setup_zone_pageset(zone);
#endif
        /* we have to stop all cpus to guarantee there is no user
           of zonelist */
        stop_machine(__build_all_zonelists, pgdat, NULL);
        /* cpuset refresh routine should be here */
    }
```

### __build_all_zonelists

https://github.com/novelinux/linux-4.x.y/tree/master/mm/page_alloc.c/__build_all_zonelists.md

### mminit_verify_zonelist

### cpuset_init_current_mems_allowed

other
----------------------------------------

```
    /* 得到所有管理区可分配的空闲页面数 */
    vm_total_pages = nr_free_pagecache_pages();
    /*
     * Disable grouping by mobility if the number of pages in the
     * system is too low to allow the mechanism to work. It would be
     * more accurate, but expensive to check per-zone. This check is
     * made on memory-hotadd so a system can start with mobility
     * disabled and enable it later
     */
    if (vm_total_pages < (pageblock_nr_pages * MIGRATE_TYPES))
        page_group_by_mobility_disabled = 1;
    else
        page_group_by_mobility_disabled = 0;

    pr_info("Built %i zonelists in %s order, mobility grouping %s.  "
        "Total pages: %ld\n",
            nr_online_nodes,
            zonelist_order_name[current_zonelist_order],
            page_group_by_mobility_disabled ? "off" : "on",
            vm_total_pages);
#ifdef CONFIG_NUMA
    pr_info("Policy zone: %s\n", zone_names[policy_zone]);
#endif
}
```