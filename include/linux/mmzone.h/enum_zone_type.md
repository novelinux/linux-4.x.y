enum zone_type
========================================

ZONE_DMA
----------------------------------------

ZONE_DMA标记适合DMA的内存域。该区域的长度依赖于处理器类型。

path: include/linux/mmzone.h
```
enum zone_type {
#ifdef CONFIG_ZONE_DMA
    /*
     * ZONE_DMA is used when there are devices that are not able
     * to do DMA to all of addressable memory (ZONE_NORMAL). Then we
     * carve out the portion of memory that is needed for these devices.
     * The range is arch specific.
     *
     * Some examples
     *
     * Architecture        Limit
     * ---------------------------
     * parisc, ia64, sparc    <4G
     * s390            <2G
     * arm            Various
     * alpha        Unlimited or 0-16MB.
     *
     * i386, x86_64 and multiple other arches
     *             <16M.
     */
    ZONE_DMA,
#endif
```

ZONE_DMA32
----------------------------------------

ZONE_DMA32标记了使用32位地址字可寻址、适合DMA的内存域。显然，只有在64位系统上，两种DMA内存域才有
差别。在32位计算机上，本内存域是空的，即长度为0MiB。在Alpha和AMD64系统上，该内存域的长度可能
从0到4 GiB。

```
#ifdef CONFIG_ZONE_DMA32
    /*
     * x86_64 needs two ZONE_DMAs because it supports devices that are
     * only able to do DMA to the lower 16M but also 32 bit devices that
     * can only do DMA areas below 4G.
     */
    ZONE_DMA32,
#endif
```

ZONE_NORMAL
----------------------------------------

ZONE_NORMAL标记了可直接映射到内核段的普通内存域。这是在所有体系结构上保证都会存在的唯一内存域，
但无法保证该地址范围对应了实际的物理内存。例如，如果AMD64系统有2 GiB内存，那么所有内存都属于
ZONE_DMA32范围，而ZONE_NORMAL则为空。

```
    /*
     * Normal addressable memory is in ZONE_NORMAL. DMA operations can be
     * performed on pages in ZONE_NORMAL if the DMA devices support
     * transfers to all addressable memory.
     */
    ZONE_NORMAL,
```

ZONE_HIGHMEM
----------------------------------------

ZONE_HIGHMEM标记了超出内核段的物理内存。根据编译时的配置，可能无需考虑某些内存域。例如在64位系统
中，并不需要高端内存域。如果支持了只能访问4 GiB以下内存的32位外设，才需要DMA32内存域。

```
#ifdef CONFIG_HIGHMEM
    /*
     * A memory area that is only addressable by the kernel through
     * mapping portions into its own address space. This is for example
     * used by i386 to allow the kernel to address the memory beyond
     * 900MB. The kernel will set up special mappings (page
     * table entries on i386) for each page that the kernel needs to
     * access.
     */
    ZONE_HIGHMEM,
#endif
```

ZONE_MOVABLE
----------------------------------------

内核定义了一个伪内存域ZONE_MOVABLE，在防止物理内存碎片的机制中需要使用该内存域。

```
    ZONE_MOVABLE,
#ifdef CONFIG_ZONE_DEVICE
    ZONE_DEVICE,
#endif
    __MAX_NR_ZONES

};
```

aries
----------------------------------------

```
CONFIG_HIGHMEM=y
# CONFIG_ZONE_DMA is not set
# CONFIG_ZONE_DMA32 is not set
```