struct per_cpu_pageset
========================================

path: include/linux/mmzone.h
```
struct per_cpu_pageset {
    struct per_cpu_pages pcp;
#ifdef CONFIG_NUMA
    s8 expire;
#endif
#ifdef CONFIG_SMP
    s8 stat_threshold;
    s8 vm_stat_diff[NR_VM_ZONE_STAT_ITEMS];
#endif
};
```

struct per_cpu_pages
----------------------------------------

热页放置在列表头部，而冷页置于列表尾部。通过测量发现，与一个列表相比，两个独立的列表不会带来
实质性的好处，因此引入了该修改。

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/mmzone.h/struct_per_cpu_pages.md
