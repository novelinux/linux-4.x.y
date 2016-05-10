pgd_addr_end
========================================

path: include/asm-generic/pgtable.h
```
/*
 * When walking page tables, get the address of the next boundary,
 * or the end address of the range if that comes earlier.  Although no
 * vma end wraps to 0, rounded up __boundary may wrap to 0 throughout.
 */

#define pgd_addr_end(addr, end)                                         \
({    unsigned long __boundary = ((addr) + PGDIR_SIZE) & PGDIR_MASK;    \
    (__boundary - 1 < (end) - 1)? __boundary: (end);                    \
})
```

PGDIR_SIZE vs PGDIR_MASK
----------------------------------------

### ARM

https://github.com/leeminghao/doc-linux/blob/master/4.x.y/arch/arm/include/asm/pgtable-2level.h/PGDIR_XXX.md
