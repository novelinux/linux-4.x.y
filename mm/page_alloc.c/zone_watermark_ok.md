zone_watermark_ok
========================================

zone_watermark_ok用设置的标志来检查所遍历到的内存域是否有足够的空闲页，
该函数根据设置的标志判断是否能从给定的内存域分配内存。

path: mm/page_alloc.c
```
bool zone_watermark_ok(struct zone *z, unsigned int order, unsigned long mark,
              int classzone_idx, int alloc_flags)
{
    return __zone_watermark_ok(z, order, mark, classzone_idx, alloc_flags,
                    zone_page_state(z, NR_FREE_PAGES));
}
```

__zone_watermark_ok
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/mm/page_alloc.c/__zone_watermark_ok.md
