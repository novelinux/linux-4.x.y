dma_contiguous_remap
========================================

path: arch/arm/mm/dma-mapping.c
```
struct dma_contig_early_reserve {
    phys_addr_t base;
    unsigned long size;
};

static struct dma_contig_early_reserve dma_mmu_remap[MAX_CMA_AREAS] __initdata;

static int dma_mmu_remap_num __initdata;

void __init dma_contiguous_early_fixup(phys_addr_t base, unsigned long size)
{
    dma_mmu_remap[dma_mmu_remap_num].base = base;
    dma_mmu_remap[dma_mmu_remap_num].size = size;
    dma_mmu_remap_num++;
}

void __init dma_contiguous_remap(void)
{
    int i;
    for (i = 0; i < dma_mmu_remap_num; i++) {
        phys_addr_t start = dma_mmu_remap[i].base;
        phys_addr_t end = start + dma_mmu_remap[i].size;
        struct map_desc map;
        unsigned long addr;

        if (end > arm_lowmem_limit)
            end = arm_lowmem_limit;
        if (start >= end)
            continue;

        map.pfn = __phys_to_pfn(start);
        map.virtual = __phys_to_virt(start);
        map.length = end - start;
        map.type = MT_MEMORY_DMA_READY;

        /*
         * Clear previous low-memory mapping to ensure that the
         * TLB does not see any conflicting entries, then flush
         * the TLB of the old entries before creating new mappings.
         *
         * This ensures that any speculatively loaded TLB entries
         * (even though they may be rare) can not cause any problems,
         * and ensures that this code is architecturally compliant.
         */
        for (addr = __phys_to_virt(start); addr < __phys_to_virt(end);
             addr += PMD_SIZE)
            pmd_clear(pmd_off_k(addr));

        flush_tlb_kernel_range(__phys_to_virt(start),
                       __phys_to_virt(end));

        iotable_init(&map, 1);
    }
}
```