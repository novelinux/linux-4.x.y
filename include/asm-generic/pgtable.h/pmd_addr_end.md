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

https://github.com/leeminghao/doc-linux/blob/master/4.x.y/arch/arm/include/asm/pgtable-2level.h/PMD_XXX.md
