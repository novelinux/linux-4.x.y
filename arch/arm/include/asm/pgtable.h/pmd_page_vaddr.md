pmd_page_vaddr
========================================

path: arch/arm/include/asm/pgtable.h
```
static inline pte_t *pmd_page_vaddr(pmd_t pmd)
{
        return __va(pmd_val(pmd) & PHYS_MASK & (s32)PAGE_MASK);
}
```