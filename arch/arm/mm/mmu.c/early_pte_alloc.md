early_pte_alloc
========================================

early_pte_alloc函数判断对应的pmd所指向的L2(PTE)页表是否存在，如果不存在就分配L2(PTE)页表，
最后返回虚拟地址addr在PTE页表中对应的偏移量的虚拟地址.

path: arch/arm/mm/mmu.c
```
static pte_t * __init early_pte_alloc(pmd_t *pmd, unsigned long addr, unsigned long prot)
{
    // 首先判断pmd指向的L1页表中的页表项是否存在，如果不存在则首先使用early_alloc函数申请所需
    // 的二级页表空间，大小为4K，1个PAGE。
    if (pmd_none(*pmd)) {
        // PTE_HWTABLE_OFF（512*4=2KB）+ PTE_HWTABLE_SIZE（512*4=2KB）总计
        // 4KB的一个物理页来存储2个linux PTE页表 + 2个hw PTE页表。
        pte_t *pte = early_alloc(PTE_HWTABLE_OFF + PTE_HWTABLE_SIZE);

        // 2个L2页表已经建立，该函数的作用就是设置L1页表的对应表项，使其指向刚建立的2个L2页表
        // (hwpte0，hwpte1)，正如前面所说，linux的L1页表项是8个字节大小.
        __pmd_populate(pmd, __pa(pte), prot);
    }
    BUG_ON(pmd_bad(*pmd));
    return pte_offset_kernel(pmd, addr);
}
```

PTE_HWTABLE_OFF vs PTE_HWTABLE_SIZE
----------------------------------------

https://github.com/leeminghao/doc-linux/blob/master/4.x.y/arch/arm/include/asm/pgtable-2level.h/PTE_HWTABLE_XXX.md

early_alloc
----------------------------------------

https://github.com/leeminghao/doc-linux/blob/master/4.x.y/arch/arm/mm/mmu.c/early_alloc.md

__pmd_populate
----------------------------------------

https://github.com/leeminghao/doc-linux/blob/master/4.x.y/arch/arm/include/asm/pgalloc.h/__pmd_populate.md

pte_offset_kernel
----------------------------------------

https://github.com/leeminghao/doc-linux/blob/master/4.x.y/arch/arm/include/asm/pgtable.h/pte_offset_kernel.md
