__map_init_section
========================================

由于pgd是一个2维数组，所以每次需要对2个元素赋值，也即一次可以处理2M的内存映射，生成两个页表项。
它在一个循环中以SECTION_SIZE为步进单位，通过phys | type->prot_sect来生成和填充页表。
主RAM内存就是通过这种方法生成。

path: arch/arm/mm/mmu.c
```
static void __init __map_init_section(pmd_t *pmd, unsigned long addr,
            unsigned long end, phys_addr_t phys,
            const struct mem_type *type)
{
    pmd_t *p = pmd;

#ifndef CONFIG_ARM_LPAE
    /*
     * In classic MMU format, puds and pmds are folded in to
     * the pgds. pmd_offset gives the PGD entry. PGDs refer to a
     * group of L1 entries making up one logical pointer to
     * an L2 table (2MB), where as PMDs refer to the individual
     * L1 entries (1MB). Hence increment to get the correct
     * offset for odd 1MB sections.
     * (See arch/arm/include/asm/pgtable-2level.h)
     */
    if (addr & SECTION_SIZE)
        pmd++;
#endif
    do {
        *pmd = __pmd(phys | type->prot_sect);
        phys += SECTION_SIZE;
    } while (pmd++, addr += SECTION_SIZE, addr != end);

    // 调用flush_pmd_entry清空TLB中的页面Cache，以使得新页表起作用。
    flush_pmd_entry(p);
}
```