PFN
========================================

path: include/linux/pfn.h
```
#define PFN_ALIGN(x)   (((unsigned long)(x) + (PAGE_SIZE - 1)) & PAGE_MASK)
#define PFN_UP(x)      (((x) + PAGE_SIZE-1) >> PAGE_SHIFT)
#define PFN_DOWN(x)    ((x) >> PAGE_SHIFT)
#define PFN_PHYS(x)    ((phys_addr_t)(x) << PAGE_SHIFT)
```

PAGE_XXX
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/arch/arm/include/asm/page.h/page.h.md
