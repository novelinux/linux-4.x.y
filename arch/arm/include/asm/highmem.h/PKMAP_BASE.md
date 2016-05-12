PKMAP_BASE
========================================

持久内核映射区域的起始和结束定义如下：

path: arch/arm/include/asm/highmem.h
```
#define PKMAP_BASE    (PAGE_OFFSET - PMD_SIZE)
#define LAST_PKMAP    PTRS_PER_PTE
```

PKMAP_BASE定义了其起始地址, LAST_PKMAP定义了容纳该映射所需的页数。

PAGE_OFFSET
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/arch/arm/include/asm/memory.h/PAGE_OFFSET.md

PMD_SIZE
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/arch/arm/include/asm/pgtable-2level.h/PMD_XXX.md

PTRS_PER_PTE
----------------------------------------

https://github.com/novelinux/linux-4.x.y/blob/master/arch/arm/include/asm/pgtable-2level.h/PTE_HWTABLE_XXX.md
