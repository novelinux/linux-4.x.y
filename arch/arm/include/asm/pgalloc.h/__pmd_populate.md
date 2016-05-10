__pmd_populate
========================================

__pmd_populate同时处理两个一级页表项pmd[0]和pmd[1]。

path: arch/arm/include/asm/pgalloc.h
```
static inline void __pmd_populate(pmd_t *pmdp, phys_addr_t pte,
                  pmdval_t prot)
{
    pmdval_t pmdval = (pte + PTE_HWTABLE_OFF) | prot;
    // pmd[0]的值即为pmdval，也即通过early_alloc(memblock算法)分配的物理页面地址pte
    // 转化为物理地址后加上保护标志。
    pmdp[0] = __pmd(pmdval);
#ifndef CONFIG_ARM_LPAE
    // pmd[1]的值是pmd[0]的值的偏移，它偏移了256个PTE页表项，由于每个PTE页表项也是4字节，
    // 所以偏移的的物理地址为256 * sizeof(pte_t)。
    pmdp[1] = __pmd(pmdval + 256 * sizeof(pte_t));
#endif
    // 刷新TLB缓冲，使系统的cpu都可以看见该映射的变化
    flush_pmd_entry(pmdp);
}
```