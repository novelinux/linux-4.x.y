gfp_zone
========================================

gfp_zone的目的是为了使用对应的mask值找到最合适的zone类型.

计算与给定分配标志兼容的最高内存域,那么内存分配可以从该内存域或更低的内存域进行。

path: include/linux/gfp.h
```
static inline enum zone_type gfp_zone(gfp_t flags)
{
    enum zone_type z;
    int bit = (__force int) (flags & GFP_ZONEMASK);

    z = (GFP_ZONE_TABLE >> (bit * ZONES_SHIFT)) &
                     ((1 << ZONES_SHIFT) - 1);
    VM_BUG_ON((GFP_ZONE_BAD >> bit) & 1);
    return z;
}
```

GFP_ZONEMASK
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/gfp.h/mask.md

GFP_ZONE_TABLE
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/gfp.h/GFP_ZONE_TABLE.md
