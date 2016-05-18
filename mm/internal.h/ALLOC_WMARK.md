ALLOC_WMARK
========================================

如下标志用于控制到达各个水印指定的临界状态时的行为。

path: mm/internal.h
```
/* The ALLOC_WMARK bits are used as an index to zone->watermark */
#define ALLOC_WMARK_MIN        WMARK_MIN
#define ALLOC_WMARK_LOW        WMARK_LOW
#define ALLOC_WMARK_HIGH       WMARK_HIGH
#define ALLOC_NO_WATERMARKS    0x04 /* don't check watermarks at all */

/* Mask to get the watermark bits */
#define ALLOC_WMARK_MASK    (ALLOC_NO_WATERMARKS-1)

#define ALLOC_HARDER        0x10 /* try to alloc harder */
#define ALLOC_HIGH          0x20 /* __GFP_HIGH set */
#define ALLOC_CPUSET        0x40 /* check for correct cpuset */
#define ALLOC_CMA           0x80 /* allow allocations from CMA areas */
#define ALLOC_FAIR          0x100 /* fair zone allocation */
```

* ALLOC_WMARK_HIGH

只有内存域包含页的数目至少为zone->watermark[WMARK_HIGH]时，才能分配页。

* ALLOC_WMARK_MIN vs ALLOC_WMARK_LOW。

使用较低(zone->watermark[WMARK_LOW])或最低(zone->watermark[WMARK_MIN])设置.

* ALLOC_HARDER

通知伙伴系统在急需内存时放宽分配规则。

* ALLOC_HIGH

在分配高端内存域的内存时，进一步放宽限制。*

* ALLOC_CPUSET

告知内核，内存只能从当前进程允许运行的CPU相关联的内存结点分配，当然该选项只对NUMA系统有意义

zone_watermark_ok
----------------------------------------

该函数根据设置的标志判断是否能从给定的内存域分配内存.

https://github.com/novelinux/linux-4.x.y/tree/master/mm/page_alloc.c/zone_watermark_ok.md

enum zone_watermarks
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/mmzone.h/enum_zone_watermarks.md