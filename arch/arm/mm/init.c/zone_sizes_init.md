zone_sizes_init
========================================

体系结构相关代码需要在启动期间建立以下信息：

* 系统中各个内存域的页帧边界，保存在max_zone_pfn数组；
* 各结点页帧的分配情况，保存在全局变量early_node_map中。

zone_sizes_init会初始化系统中Node 0的pg_data_t实例。初始化Node(pg_data_t)管理的各Zone(struct zone)
的大小(单位为page - 4KB). 一般是三个内存域ZONE_DMA, ZONE_NORMAL, ZONE_HIGHMEM. 通常DMA的相关操作
也会从NORMAL中分配内存, 其关系如下所示:

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/mmzone.h/res/node_zone_page.gif

### enum zone_type

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/mmzone.h/enum_zone_type.md

Arguments
----------------------------------------

path: arch/arm/mm/init.c
```
static void __init zone_sizes_init(unsigned long min, unsigned long max_low,
    unsigned long max_high)
{
```

### aries

```
min=80200, max_low=afa00, max_high=fffff
```

ZONE_NORMAL or ZONE_DMA
----------------------------------------

```
    unsigned long zone_size[MAX_NR_ZONES], zhole_size[MAX_NR_ZONES];
    struct memblock_region *reg;

    /*
     * initialise the zones.
     */
    memset(zone_size, 0, sizeof(zone_size));

    /*
     * The memory size has already been determined.  If we need
     * to do anything fancy with the allocation of this memory
     * to the zones, now is the time to do it.
     */
    zone_size[0] = max_low - min;
```

### aries

```
zone_size[0]=194560
# cat /proc/zoneinfo
Node 0, zone   Normal
...
        spanned  194560
...
```

ZONE_HIGHMEM
----------------------------------------

```
#ifdef CONFIG_HIGHMEM
    zone_size[ZONE_HIGHMEM] = max_high - max_low;
#endif

    /*
     * Calculate the size of the holes.
     *  holes = node_size - sum(bank_sizes)
     */
    memcpy(zhole_size, zone_size, sizeof(zhole_size));
    for_each_memblock(memory, reg) {
        unsigned long start = memblock_region_memory_base_pfn(reg);
        unsigned long end = memblock_region_memory_end_pfn(reg);

        if (start < max_low) {
            unsigned long low_end = min(end, max_low);
            zhole_size[0] -= low_end - start;
        }
#ifdef CONFIG_HIGHMEM
        if (end > max_low) {
            unsigned long high_start = max(start, max_low);
            zhole_size[ZONE_HIGHMEM] -= end - high_start;
        }
#endif
    }
```

### aries

```
zone_size[ZONE_HIGHMEM]=329215
Node 0, zone  HighMem
...
        spanned  329215
...
```

ZONE_DMA
----------------------------------------

```
#ifdef CONFIG_ZONE_DMA
    /*
     * Adjust the sizes according to any special requirements for
     * this machine type.
     */
    if (arm_dma_zone_size)
        arm_adjust_dma_zone(zone_size, zhole_size,
            arm_dma_zone_size >> PAGE_SHIFT);
#endif
```

free_area_init_node
--------------------------------------

从内核版本2.6.10开始提供了一个通用框架，用于将上述信息转换为伙伴系统预期的结点和内存域数据结构。
在这以前，各个体系结构必须自行建立相关结构。现在，体系结构相关代码只需要建立前述的简单结构，
将繁重的工作留给free_area_init_node即, 可在获取了三个管理区的页面数后，通过
free_area_init_node()来初始化Node 0相应的管理数据结构.

```
    free_area_init_node(0, zone_size, min, zhole_size);
}
```

https://github.com/novelinux/linux-4.x.y/tree/master/mm/page_alloc.c/free_area_init_node.md
