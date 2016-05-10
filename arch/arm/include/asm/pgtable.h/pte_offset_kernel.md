pte_offset_kernel
========================================

path: arch/arm/include/asm/pgtable.h
```
define pte_offset_kernel(pmd,addr)    (pmd_page_vaddr(*(pmd)) + pte_index(addr))
```

pmd_page_vaddr
----------------------------------------

https://github.com/leeminghao/doc-linux/blob/master/4.x.y/arch/arm/include/asm/pgtable.h/pmd_page_vaddr.md

pte_index
----------------------------------------

https://github.com/leeminghao/doc-linux/blob/master/4.x.y/arch/arm/include/asm/pgtable.h/pte_index.md
