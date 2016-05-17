GFP_ZONE_TABLE
========================================

path: include/linux/gfp.h
```
#ifdef CONFIG_HIGHMEM
#define OPT_ZONE_HIGHMEM ZONE_HIGHMEM
#else
#define OPT_ZONE_HIGHMEM ZONE_NORMAL
#endif

#ifdef CONFIG_ZONE_DMA
#define OPT_ZONE_DMA ZONE_DMA
#else
#define OPT_ZONE_DMA ZONE_NORMAL
#endif

#ifdef CONFIG_ZONE_DMA32
#define OPT_ZONE_DMA32 ZONE_DMA32
#else
#define OPT_ZONE_DMA32 ZONE_NORMAL
#endif

/*
 * GFP_ZONE_TABLE is a word size bitstring that is used for looking up the
 * zone to use given the lowest 4 bits of gfp_t. Entries are ZONE_SHIFT long
 * and there are 16 of them to cover all possible combinations of
 * __GFP_DMA, __GFP_DMA32, __GFP_MOVABLE and __GFP_HIGHMEM.
 *
 * The zone fallback order is MOVABLE=>HIGHMEM=>NORMAL=>DMA32=>DMA.
 * But GFP_MOVABLE is not only a zone specifier but also an allocation
 * policy. Therefore __GFP_MOVABLE plus another zone selector is valid.
 * Only 1 bit of the lowest 3 bits (DMA,DMA32,HIGHMEM) can be set to "1".
 *
 *       bit       result
 *       =================
 *       0x0    => NORMAL
 *       0x1    => DMA or NORMAL
 *       0x2    => HIGHMEM or NORMAL
 *       0x3    => BAD (DMA+HIGHMEM)
 *       0x4    => DMA32 or DMA or NORMAL
 *       0x5    => BAD (DMA+DMA32)
 *       0x6    => BAD (HIGHMEM+DMA32)
 *       0x7    => BAD (HIGHMEM+DMA32+DMA)
 *       0x8    => NORMAL (MOVABLE+0)
 *       0x9    => DMA or NORMAL (MOVABLE+DMA)
 *       0xa    => MOVABLE (Movable is valid only if HIGHMEM is set too)
 *       0xb    => BAD (MOVABLE+HIGHMEM+DMA)
 *       0xc    => DMA32 (MOVABLE+DMA32)
 *       0xd    => BAD (MOVABLE+DMA32+DMA)
 *       0xe    => BAD (MOVABLE+DMA32+HIGHMEM)
 *       0xf    => BAD (MOVABLE+DMA32+HIGHMEM+DMA)
 *
 * ZONES_SHIFT must be <= 2 on 32 bit platforms.
 */

#if 16 * ZONES_SHIFT > BITS_PER_LONG
#error ZONES_SHIFT too large to create GFP_ZONE_TABLE integer
#endif

#define GFP_ZONE_TABLE (                                                  \
    (ZONE_NORMAL << 0 * ZONES_SHIFT)                                      \
    | (OPT_ZONE_DMA << ___GFP_DMA * ZONES_SHIFT)                          \
    | (OPT_ZONE_HIGHMEM << ___GFP_HIGHMEM * ZONES_SHIFT)                  \
    | (OPT_ZONE_DMA32 << ___GFP_DMA32 * ZONES_SHIFT)                      \
    | (ZONE_NORMAL << ___GFP_MOVABLE * ZONES_SHIFT)                       \
    | (OPT_ZONE_DMA << (___GFP_MOVABLE | ___GFP_DMA) * ZONES_SHIFT)       \
    | (ZONE_MOVABLE << (___GFP_MOVABLE | ___GFP_HIGHMEM) * ZONES_SHIFT)   \
    | (OPT_ZONE_DMA32 << (___GFP_MOVABLE | ___GFP_DMA32) * ZONES_SHIFT)   \
)
```

如果__GFP_DMA和__GFP_HIGHMEM都没有设置，则首先扫描ZONE_NORMAL，后面是ZONE_DMA。如果设置了
__GFP_HIGHMEM，没有设置__GFP_DMA，则结果是从ZONE_HIGHMEM开始扫描所有3个内存域。如果设置了
__GFP_DMA，那么__GFP_HIGHMEM设置与否没有关系。只有ZONE_DMA用于3种情形。这是合理的，
因为同时使用__GFP_HIGHMEM和__GFP_DMA没有意义。高端内存从来都不适用于DMA。

设置__GFP_MOVABLE不会影响内核的决策，除非它与__GFP_HIGHMEM同时指定。在这种情况下，会使用特殊的
虚拟内存域ZONE_MOVABLE满足内存分配请求。对前文描述的内核的反碎片策略而言，这种行为是必要的。

ZONES_SHIFT
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/page-flags-layout.h/ZONES_SHIFT.md
