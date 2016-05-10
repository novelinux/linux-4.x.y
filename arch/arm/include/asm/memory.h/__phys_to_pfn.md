__phys_to_pfn
========================================

path: arch/arm/include/asm/memory.h
```
/*
 * Convert a physical address to a Page Frame Number and back
 */
#define    __phys_to_pfn(paddr)  ((unsigned long)((paddr) >> PAGE_SHIFT))
#define    __pfn_to_phys(pfn)    ((phys_addr_t)(pfn) << PAGE_SHIFT)
```

PAGE_SHIFT
----------------------------------------

https://github.com/leeminghao/doc-linux/blob/master/4.x.y/arch/arm/include/asm/page.h/page.h.md
