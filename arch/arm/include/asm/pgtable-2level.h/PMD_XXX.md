PMD_SIZE
========================================

path: arch/arm/include/asm/pgtable-2level.h
```
/*
 * PMD_SHIFT determines the size of the area a second-level page table can map
 * PGDIR_SHIFT determines what a third-level page table entry can map
 */
#define PMD_SHIFT        21
...

#define PMD_SIZE        (1UL << PMD_SHIFT) // 2MB
#define PMD_MASK        (~(PMD_SIZE-1))
```