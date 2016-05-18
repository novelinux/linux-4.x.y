wake_all_kswapds
========================================

内核再次遍历备用列表中的所有内存域，每次都调用wakeup_kswapd。顾名思义，该函数会唤醒负责换出页的
kswapd守护进程。交换守护进程的任务比较复杂，在这里需要注意的是，空闲内存可以通过缩减内核缓存和
页面回收获得，即写回或换出很少使用的页。这两种措施都是由该守护进程发起的。

path: mm/page_alloc.c
```
static void wake_all_kswapds(unsigned int order, const struct alloc_context *ac)
{
    struct zoneref *z;
    struct zone *zone;

    for_each_zone_zonelist_nodemask(zone, z, ac->zonelist,
                        ac->high_zoneidx, ac->nodemask)
        wakeup_kswapd(zone, order, zone_idx(ac->preferred_zone));
}
```

wakeup_kswapd
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/mm/vmscan.c/wakeup_kswapd.md
