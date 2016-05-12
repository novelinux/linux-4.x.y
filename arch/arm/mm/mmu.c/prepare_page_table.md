prepare_page_table
========================================

几个重要的宏定义:

* PMD_SIZE

https://github.com/novelinux/linux-4.x.y/tree/master/arch/arm/include/asm/pgtable-2level.h/PMD_XXX.md

* MODULES_VADDR

https://github.com/novelinux/linux-4.x.y/tree/master/arch/arm/include/asm/memory.h/MODULES_VADDR.md

* PAGE_OFFSET

https://github.com/novelinux/linux-4.x.y/tree/master/arch/arm/include/asm/memory.h/PAGE_OFFSET.md

* VMALLOC_START

https://github.com/novelinux/linux-4.x.y/tree/master/arch/arm/include/asm/pgtable.h/VMALLOC.md

prepare_page_table
----------------------------------------

调用prepare_page_table初始化虚拟地址[0, PAGE_OFFSET]和[memory.regions[0].start +
memory.regions[0].size, VMALLOC_END]所对应的主页表项，所有表项均初始化为0。

这里保留了内核代码区，主页表区以及memblock机制中的位图映射区对应的主页表。这是为了保证内核代码
的执行以及对主页表区和位图区的访问。

path: arch/arm/mm/mmu.c
```
static inline void prepare_page_table(void)
{
    unsigned long addr;
    phys_addr_t end;

    /*
     * Clear out all the mappings below the kernel image.
     */
     /*1.清除0~MODULES_VADDR区间的内存映射关系*/
    for (addr = 0; addr < MODULES_VADDR; addr += PMD_SIZE)
        pmd_clear(pmd_off_k(addr));

#ifdef CONFIG_XIP_KERNEL
    /* The XIP kernel is mapped in the module area -- skip over it */
    addr = ((unsigned long)_etext + PMD_SIZE - 1) & PMD_MASK;
#endif
    /* 2.清除MODULES_VADDR ~ PAGE_OFFSET区间的内存映射关系 */
    for ( ; addr < PAGE_OFFSET; addr += PMD_SIZE)
        pmd_clear(pmd_off_k(addr));

    /*
     * Find the end of the first block of lowmem.
     */
     // regions[0].base和regions[0].size分别记录第一个内存regions的起始物理地址和大小
    end = memblock.memory.regions[0].base + memblock.memory.regions[0].size;
    if (end >= arm_lowmem_limit)
        end = arm_lowmem_limit;

    /*
     * Clear out all the kernel space mappings, except for the first
     * memory bank, up to the vmalloc region.
     */
     /* 3.清除high_memory(arm_lowmem_limit) ~ VMALLOC_START段映射. */
    for (addr = __phys_to_virt(end);
         addr < VMALLOC_START; addr += PMD_SIZE)
             pmd_clear(pmd_off_k(addr));
}
```

pmd_off_k
----------------------------------------

pmd_off_k查找一个虚拟地址的内核页表目录项.

pmd_clear
----------------------------------------
