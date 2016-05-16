MAX_ORDER
========================================

path: include/linux/mmzone.h
```
/* Free memory management - zoned buddy allocator.  */
#ifndef CONFIG_FORCE_MAX_ZONEORDER
#define MAX_ORDER 11
#else
#define MAX_ORDER CONFIG_FORCE_MAX_ZONEORDER
#endif
#define MAX_ORDER_NR_PAGES (1 << (MAX_ORDER - 1))
```

aries
----------------------------------------

```
CONFIG_FORCE_MAX_ZONEORDER=11
```

该常数通常设置为11，这意味着一次分配可以请求的页数最大是2^11=2 048。但如果特定于体系结构的
代码设置了FORCE_MAX_ZONEORDER配置选项，该值也可以手工改变。