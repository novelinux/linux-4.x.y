pmd_addr_end
========================================

path: include/asm-generic/pgtable.h
```
#ifndef pmd_addr_end
#define pmd_addr_end(addr, end)                                     \
({    unsigned long __boundary = ((addr) + PMD_SIZE) & PMD_MASK;    \
    (__boundary - 1 < (end) - 1)? __boundary: (end);                \
})
#endif
```

PMD_SIZE vs PMD_MASK
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/arch/arm/include/asm/pgtable-2level.h/PMD_XXX.md
