_PAGE_KERNEL_TABLE
========================================

path: arch/arm/include/asm/pgalloc.h
```
#ifdef CONFIG_MMU
...
#define _PAGE_KERNEL_TABLE	(PMD_TYPE_TABLE | PMD_BIT4 | PMD_DOMAIN(DOMAIN_KERNEL))
#endif
```