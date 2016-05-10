__build_all_zonelists
========================================

__build_all_zonelists对系统中的各个NUMA结点分别调用build_zonelists。该函数的任务是，
在当前处理的结点和系统中其他结点的内存域之间建立一种等级次序。接下来，依据这种次序分配内存。
如果在期望的结点内存域中，没有空闲内存，那么这种次序就很重要。

我们考虑一个例子，其中内核想要分配高端内存。它首先企图在当前结点的高端内存域找到一个大小适当的
空闲段。如果失败，则查看该结点的普通内存域。如果还失败，则试图在该结点的DMA内存域执行分配。
如果在3个本地内存域都无法找到空闲内存，则查看其他结点。在这种情况下，备选结点应该尽可能靠近
主结点，以最小化由于访问非本地内存引起的性能损失。

内核定义了内存的一个层次结构，首先试图分配“廉价的”内存。如果失败，则根据访问速度和容量，
逐渐尝试分配“更昂贵的”内存。

高端内存是最廉价的，因为内核没有任何部份依赖于从该内存域分配的内存。如果高端内存域用尽，
对内核没有任何副作用，这也是优先分配高端内存的原因。

普通内存域的情况有所不同。许多内核数据结构必须保存在该内存域，而不能放置到高端内存域。因此
如果普通内存完全用尽，那么内核会面临紧急情况。所以只要高端内存域的内存没有用尽，都不会从
普通内存域分配内存。

最昂贵的是DMA内存域，因为它用于外设和系统之间的数据传输。因此从该内存域分配内存是最后一招。
内核还针对当前内存结点的备选结点，定义了一个等级次序。这有助于在当前结点所有内存域的内存
都用尽时，确定一个备选结点。

for_each_online_node
----------------------------------------

for_each_online_node遍历了系统中所有的活动结点。由于UMA系统只有一个结点，build_zonelists
只调用了一次，就对所有的内存创建了内存域列表。NUMA系统调用该函数的次数等同于结点的数目。
每次调用对一个不同结点生成内存域数据。

path: mm/page_alloc.c
```
static int __build_all_zonelists(void *data)
{
    int nid;
    int cpu;
    pg_data_t *self = data;

#ifdef CONFIG_NUMA
    memset(node_load, 0, sizeof(node_load));
#endif

    if (self && !node_online(self->node_id)) {
        build_zonelists(self);
        build_zonelist_cache(self);
    }

    for_each_online_node(nid) {
```

https://github.com/leeminghao/doc-linux/tree/master/4.x.y/include/linux/nodemask.h/for_each_online_node.md

NODE_DATA
----------------------------------------

在UMA系统上，NODE_DATA返回contig_page_data的地址。

```
        pg_data_t *pgdat = NODE_DATA(nid);
```

https://github.com/leeminghao/doc-linux/tree/master/4.x.y/include/linux/mmzone.h/NODE_DATA.md

### UMA

在UMA系统上contig_page_data的初始化如下所示:

https://github.com/novelinux/linux-4.x.y/tree/master/arch/arm/mm/init.c/bootmem_init.md

build_zonelists
----------------------------------------

```
        build_zonelists(pgdat);
```

https://github.com/novelinux/linux-4.x.y/tree/master/mm/page_alloc.c/build_zonelists.md

build_zonelist_cache
----------------------------------------

```
        build_zonelist_cache(pgdat);
    }
```

setup_pageset
----------------------------------------

```
    /*
     * Initialize the boot_pagesets that are going to be used
     * for bootstrapping processors. The real pagesets for
     * each zone will be allocated later when the per cpu
     * allocator is available.
     *
     * boot_pagesets are used also for bootstrapping offline
     * cpus if the system is already booted because the pagesets
     * are needed to initialize allocators on a specific cpu too.
     * F.e. the percpu allocator needs the page allocator which
     * needs the percpu allocator in order to allocate its pagesets
     * (a chicken-egg dilemma).
     */
    for_each_possible_cpu(cpu) {
        setup_pageset(&per_cpu(boot_pageset, cpu), 0);

#ifdef CONFIG_HAVE_MEMORYLESS_NODES
        /*
         * We now know the "local memory node" for each node--
         * i.e., the node of the first zone in the generic zonelist.
         * Set up numa_mem percpu variable for on-line cpus.  During
         * boot, only the boot cpu should be on-line;  we'll init the
         * secondary cpus' numa_mem as they come on-line.  During
         * node/memory hotplug, we'll fixup all on-line cpus.
         */
        if (cpu_online(cpu))
            set_cpu_numa_mem(cpu, local_memory_node(cpu_to_node(cpu)));
#endif
    }

    return 0;
}
```