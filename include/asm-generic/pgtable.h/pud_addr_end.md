pud_addr_end
========================================

path: include/asm-generic/pgtable.h
```
#ifndef pud_addr_end
#define pud_addr_end(addr, end)                                     \
({    unsigned long __boundary = ((addr) + PUD_SIZE) & PUD_MASK;    \
    (__boundary - 1 < (end) - 1)? __boundary: (end);                \
})
#endif
```

PUD_SIZE vs PUD_MASK
----------------------------------------

path: include/asm-generic/4level-fixup.h
```
#define PUD_SIZE            PGDIR_SIZE
#define PUD_MASK            PGDIR_MASK
```

PGDIR_SIZE vs PGDIR_MASK
----------------------------------------

### ARM

https://github.com/leeminghao/doc-linux/blob/master/4.x.y/arch/arm/include/asm/pgtable-2level.h/PGDIR_XXX.md
