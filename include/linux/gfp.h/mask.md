mask
========================================

缩写GFP代表获得空闲页(get free page)。

path: include/linux/gfp.h
```
/* Plain integer GFP bitmasks. Do not use this directly. */
#define ___GFP_DMA             0x01u
#define ___GFP_HIGHMEM         0x02u
#define ___GFP_DMA32           0x04u
#define ___GFP_MOVABLE         0x08u

...

/* If the above are modified, __GFP_BITS_SHIFT may need updating */

/*
 * GFP bitmasks..
 *
 * Zone modifiers (see linux/mmzone.h - low three bits)
 *
 * Do not put any conditional on these. If necessary modify the definitions
 * without the underscores and use them consistently. The definitions here may
 * be used in bit comparisons.
 */
#define __GFP_DMA       ((__force gfp_t)___GFP_DMA)
#define __GFP_HIGHMEM   ((__force gfp_t)___GFP_HIGHMEM)
#define __GFP_DMA32     ((__force gfp_t)___GFP_DMA32)
#define __GFP_MOVABLE   ((__force gfp_t)___GFP_MOVABLE)  /* Page is movable */
#define GFP_ZONEMASK    (__GFP_DMA|__GFP_HIGHMEM|__GFP_DMA32|__GFP_MOVABLE)
```
