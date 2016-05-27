setup_per_cpu_areas
========================================

setup_per_cpu_areas函数为SMP的每个处理器生成per-cpu数据。per-cpu数据按照不同的CPU类别使用，
以将性能低下引发的缓存一致性（cache coherency）问题减小到最小。per-cpu数据由各cpu独立使用，
即使不锁也可访问，十分有效。在SMP系统上，setup_per_cpu_areas初始化源代码中（使用per_cpu宏）
定义的静态percpu变量，这种变量对系统中的每个CPU都有一个独立的副本。此类变量保存在内核二进制
映像的一个独立的段中。setup_per_cpu_areas的目的是为系统的各个CPU分别创建一份这些数据的副本。
在非SMP系统上该函数是一个空操作。

per-cpu变量
----------------------------------------

每CPU变量主要是数据结构的数组，系统的每个CPU对应数组的一个元素。

一个CPU不应该访问与其他CPU对应的数组元素，另外，它可以随意读或修改它自己的元素而不用担心出现
竞争条件，因为它是唯一有资格这么做的CPU。但是，这也意味着每CPU变量基本上只能在特殊情况下使用，
也就是当它确定在系统的CPU上的数据在逻辑上是独立的时候。
每CPU的数组元素在主存中被排列以使每个数据结构存放在硬件高速缓存的不同行，因此，对每CPU数组的
并发访问不会导致高速缓存行的窃用和失效（这种操作会带来昂贵的系统开销）。
虽然每CPU变量为来自不同CPU的并发访问提供保护，但对来自异步函数（中断处理程序和可延迟函数）的
访问不提供保护，在这种情况下需要另外的同步技术。
此外，在单处理器和多处理器系统中，内核抢占都可能使每CPU变量产生竞争条件。总的原则是内核控制路径
应该在禁用抢占的情况下访问每CPU变量。因为当一个内核控制路径获得了它的每CPU变量本地副本的地址，
然后它因被抢占而转移到另外一个CPU上，但仍然引用原来CPU元素的地址，这是非常危险的。

setup_per_cpu_areas
----------------------------------------

path: kernel/percpu.c
```
#ifdef CONFIG_SMP

...

#ifndef    CONFIG_HAVE_SETUP_PER_CPU_AREA
/*
 * Generic SMP percpu area setup.
 *
 * The embedding helper is used because its behavior closely resembles
 * the original non-dynamic generic percpu area setup.  This is
 * important because many archs have addressing restrictions and might
 * fail if the percpu area is located far away from the previous
 * location.  As an added bonus, in non-NUMA cases, embedding is
 * generally a good idea TLB-wise because percpu area can piggy back
 * on the physical linear memory mapping which uses large page
 * mappings on applicable archs.
 */
unsigned long __per_cpu_offset[NR_CPUS] __read_mostly;
EXPORT_SYMBOL(__per_cpu_offset);

static void * __init pcpu_dfl_fc_alloc(unsigned int cpu, size_t size,
                       size_t align)
{
    return  memblock_virt_alloc_from_nopanic(
            size, align, __pa(MAX_DMA_ADDRESS));
}

static void __init pcpu_dfl_fc_free(void *ptr, size_t size)
{
    memblock_free_early(__pa(ptr), size);
}

void __init setup_per_cpu_areas(void)
{
    unsigned long delta;
    unsigned int cpu;
    int rc;

    /*
     * Always reserve area for module percpu variables.  That's
     * what the legacy allocator did.
     */
    rc = pcpu_embed_first_chunk(PERCPU_MODULE_RESERVE,
                    PERCPU_DYNAMIC_RESERVE, PAGE_SIZE, NULL,
                    pcpu_dfl_fc_alloc, pcpu_dfl_fc_free);
    if (rc < 0)
        panic("Failed to initialize percpu areas.");

    delta = (unsigned long)pcpu_base_addr - (unsigned long)__per_cpu_start;
    for_each_possible_cpu(cpu)
        __per_cpu_offset[cpu] = delta + pcpu_unit_offsets[cpu];
}
#endif    /* CONFIG_HAVE_SETUP_PER_CPU_AREA */

...

#else    /* CONFIG_SMP */

...

#endif    /* CONFIG_SMP */
```

aries
----------------------------------------

```
CONFIG_SMP=y
```