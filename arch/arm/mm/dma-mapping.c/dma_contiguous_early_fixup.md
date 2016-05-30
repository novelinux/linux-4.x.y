dma_contiguous_early_fixup
========================================

path: arch/arm/mm/dma-mapping.c
```
void __init dma_contiguous_early_fixup(phys_addr_t base, unsigned long size)
{
    dma_mmu_remap[dma_mmu_remap_num].base = base;
    dma_mmu_remap[dma_mmu_remap_num].size = size;
    dma_mmu_remap_num++;
}
```