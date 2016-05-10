pte_index
========================================

path: arch/arm/include/asm/pgtable.h
```
#define pte_index(addr)   (((addr) >> PAGE_SHIFT) & (PTRS_PER_PTE - 1))
```