page.h
========================================

path: arch/arm/include/asm/page.h
```
/* PAGE_SHIFT determines the page size */
#define PAGE_SHIFT        12
#define PAGE_SIZE        (_AC(1,UL) << PAGE_SHIFT)
#define PAGE_MASK        (~((1 << PAGE_SHIFT) - 1))
```