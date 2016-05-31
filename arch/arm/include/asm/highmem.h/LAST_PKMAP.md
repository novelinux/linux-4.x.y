LAST_PKMAP
========================================

LAST_PKMAP定义了容纳该映射所需的页数

path: arch/arm/include/asm/highmem.h
```
#define LAST_PKMAP              PTRS_PER_PTE
#define LAST_PKMAP_MASK         (LAST_PKMAP - 1)
```

PTRS_PER_PTE
----------------------------------------

https://github.com/novelinux/linux-4.x.y/blob/master/arch/arm/include/asm/pgtable-2level.h/PTE_HWTABLE_XXX.md