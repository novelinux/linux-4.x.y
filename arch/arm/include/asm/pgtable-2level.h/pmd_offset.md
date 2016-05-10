pmd_offset
========================================

path: arch/arm/include/asm/pgtable-2level.h
```
static inline pmd_t *pmd_offset(pud_t *pud, unsigned long addr)
{
        return (pmd_t *)pud;
}
```