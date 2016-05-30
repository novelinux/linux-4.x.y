dma_mmu_remap
========================================

path: arch/arm/mm/dma-mapping.c
```
struct dma_contig_early_reserve {
    phys_addr_t base;
    unsigned long size;
};

static struct dma_contig_early_reserve dma_mmu_remap[MAX_CMA_AREAS] __initdata;

static int dma_mmu_remap_num __initdata;
```

dma_contiguous_early_fixup
----------------------------------------

dma_mmu_remap的初始化是调用函数dma_contiguous_early_fixup来完成的.

https://github.com/novelinux/linux-4.x.y/tree/master/arch/arm/mm/dma-mapping.c/dma_contiguous_early_fixup.md
