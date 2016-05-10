struct mem_type
========================================

path: arch/arm/mm/mm.h
```
struct mem_type {
    pteval_t prot_pte;
    pteval_t prot_pte_s2;
    pmdval_t prot_l1;
    pmdval_t prot_sect;
    unsigned int domain;
};
```

* prot_sect代表主页表的访问控制位和内存域。

* domain代表了内存域。在ARM处理器中，MMU将整个存储空间分成最多16个域，记作D0~D15，每个域对
  应一定的存储区域，该区域具有相同的访问控制属性。
