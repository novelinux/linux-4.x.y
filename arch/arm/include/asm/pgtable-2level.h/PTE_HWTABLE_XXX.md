PTE_HWTABLE
========================================

path: arch/arm/include/asm/pgtable-2level.h
```
#define PTRS_PER_PTE            512
#define PTRS_PER_PMD            1
#define PTRS_PER_PGD            2048

#define PTE_HWTABLE_PTRS        (PTRS_PER_PTE)
#define PTE_HWTABLE_OFF         (PTE_HWTABLE_PTRS * sizeof(pte_t))
#define PTE_HWTABLE_SIZE        (PTRS_PER_PTE * sizeof(u32))
```