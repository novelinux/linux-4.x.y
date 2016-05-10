struct cachepolicy
========================================

path: arch/arm/mm/mmu.c
```
struct cachepolicy {
    const char   policy[16];
    unsigned int cr_mask;
    pmdval_t     pmd;
    pteval_t     pte;
    pteval_t     pte_s2;
};
...
static struct cachepolicy cache_policies[] __initdata = {
    {
        .policy        = "uncached",
        .cr_mask    = CR_W|CR_C,
        .pmd        = PMD_SECT_UNCACHED,
        .pte        = L_PTE_MT_UNCACHED,
        .pte_s2        = s2_policy(L_PTE_S2_MT_UNCACHED),
    }, {
        .policy        = "buffered",
        .cr_mask    = CR_C,
        .pmd        = PMD_SECT_BUFFERED,
        .pte        = L_PTE_MT_BUFFERABLE,
        .pte_s2        = s2_policy(L_PTE_S2_MT_UNCACHED),
    }, {
        .policy        = "writethrough",
        .cr_mask    = 0,
        .pmd        = PMD_SECT_WT,
        .pte        = L_PTE_MT_WRITETHROUGH,
        .pte_s2        = s2_policy(L_PTE_S2_MT_WRITETHROUGH),
    }, {
        .policy        = "writeback",
        .cr_mask    = 0,
        .pmd        = PMD_SECT_WB,
        .pte        = L_PTE_MT_WRITEBACK,
        .pte_s2        = s2_policy(L_PTE_S2_MT_WRITEBACK),
    }, {
        .policy        = "writealloc",
        .cr_mask    = 0,
        .pmd        = PMD_SECT_WBWA,
        .pte        = L_PTE_MT_WRITEALLOC,
        .pte_s2        = s2_policy(L_PTE_S2_MT_WRITEBACK),
    }
};
```