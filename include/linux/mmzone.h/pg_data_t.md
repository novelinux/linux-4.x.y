pg_data_t
========================================

内存划分为结点, 每个结点关联到系统中的一个处理器，在内核中表示为pg_data_t的实例.
pg_data_t是用于表示结点的基本元素，定义如下：

node_zones
----------------------------------------

path: include/linux/mmzone.h
```
/*
 * The pg_data_t structure is used in machines with CONFIG_DISCONTIGMEM
 * (mostly NUMA machines?) to denote a higher-level memory zone than the
 * zone denotes.
 *
 * On NUMA machines, each NUMA node would have a pg_data_t to describe
 * it's memory layout.
 *
 * Memory statistics and page replacement data structures are maintained on a
 * per-zone basis.
 */
struct bootmem_data;
typedef struct pglist_data {
    struct zone node_zones[MAX_NR_ZONES];
```

是一个数组，包含了结点中各内存域的数据结构。

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/mmzone.h/struct_zone.md

### MAX_NR_ZONES

https://github.com/novelinux/linux-4.x.y/tree/master/kernel/bounds.c/MAX_NR_ZONES.md

node_zonelists
----------------------------------------

出于性能考虑，在为进程分配内存时，内核总是试图在当前运行的CPU相关联的NUMA结点上进行。但这并不总
是可行的，例如，该结点的内存可能已经用尽。对此类情况，每个结点都提供了一个备用列表（借助于
struct zonelist）。该列表包含了其他结点（和相关的内存域），可用于代替当前结点分配内存。列表项的
位置越靠后，就越不适合分配。

该数组用来表示所描述的层次结构。node_zonelists数组对每种可能的内存域类型，都配置
了一个独立的数组项。数组项包含了类型为zonelist的一个备用列表.由于该备用列表必须
包括所有结点的所有内存域，因此由(MAX_NUMNODES * MAX_NR_ZONES)项组成，外加一个
用于标记列表结束的空指针:

```
    struct zonelist node_zonelists[MAX_ZONELISTS];
```

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/mmzone.h/struct_zonelist.md

### MAX_ZONELISTS

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/mmzone.h/MAX_ZONELISTS.md

nr_zones
----------------------------------------

结点中不同内存域的数目

```
    int nr_zones;
```

node_mem_map
----------------------------------------

```
#ifdef CONFIG_FLAT_NODE_MEM_MAP    /* means !SPARSEMEM */
    struct page *node_mem_map;
#ifdef CONFIG_PAGE_EXTENSION
    struct page_ext *node_page_ext;
#endif
#endif
```

是指向struct page实例数组的指针，用于描述结点的所有物理内存页。它包含了结点中所有内存域的页。

### aries

```
CONFIG_FLAT_NODE_MEM_MAP=y
```

bdata
----------------------------------------

```
#ifndef CONFIG_NO_BOOTMEM
    struct bootmem_data *bdata;
#endif
```

在系统启动期间，内存管理子系统初始化之前，内核也需要使用内存(另外，还必须保留部分内存用于
初始化内存管理子系统)。为解决这个问题，内核使用了自举内存分配器（boot memory allocator）。
bdata指向自举内存分配器数据结构的实例。

node_start_pfn
----------------------------------------

```
#ifdef CONFIG_MEMORY_HOTPLUG
    /*
     * Must be held any time you expect node_start_pfn, node_present_pages
     * or node_spanned_pages stay constant.  Holding this will also
     * guarantee that any pfn_valid() stays that way.
     *
     * pgdat_resize_lock() and pgdat_resize_unlock() are provided to
     * manipulate node_size_lock without checking for CONFIG_MEMORY_HOTPLUG.
     *
     * Nests above zone->lock and zone->span_seqlock
     */
    spinlock_t node_size_lock;
#endif
    unsigned long node_start_pfn;
```

是该NUMA结点第一个页帧的逻辑编号。系统中所有结点的页帧是依次编号的，每个页帧的号码都是
全局唯一的（不只是结点内唯一）。node_start_pfn在UMA系统中总是0，因为其中只有一个结点，
因此其第一个页帧编号总是0。

node_present_pages
----------------------------------------

```
    unsigned long node_present_pages; /* total number of physical pages */
```

指定了结点中页帧的数目

node_spanned_pages
----------------------------------------

```
    unsigned long node_spanned_pages; /* total size of physical page
                         range, including holes */
```

给出了该结点以页帧为单位计算的长度。node_present_pages和node_spanned_pages二者的值不一定相同，
因为结点中可能有一些空洞，并不对应真正的页帧。

node_id
----------------------------------------

```
    int node_id;
```

是全局结点ID。系统中的NUMA结点都从0开始编号。

kswapd_wait
----------------------------------------

```
    wait_queue_head_t kswapd_wait;
```

是交换守护进程（swap daemon）的等待队列，在将页帧换出结点时会用到。

kswapd
----------------------------------------

```
    wait_queue_head_t pfmemalloc_wait;
    struct task_struct *kswapd;    /* Protected by
                       mem_hotplug_begin/end() */
```

指向负责该结点的交换守护进程的task_struct。

kswapd_max_order
----------------------------------------

```
    int kswapd_max_order;
```

用于页交换子系统的实现，用来定义需要释放的区域的长度.

zone_type
----------------------------------------

```
    enum zone_type classzone_idx;
```

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/mmzone.h/enum_zone_type.md


----------------------------------------

```
#ifdef CONFIG_NUMA_BALANCING
    /* Lock serializing the migrate rate limiting window */
    spinlock_t numabalancing_migrate_lock;

    /* Rate limiting time interval */
    unsigned long numabalancing_migrate_next_window;

    /* Number of pages migrated during the rate limiting time interval */
    unsigned long numabalancing_migrate_nr_pages;
#endif
} pg_data_t;
```

结点状态管理
----------------------------------------

https://github.com/novelinux/linux-4.x.y/blob/master/include/linux/nodemask.h/enum_node_states.md
