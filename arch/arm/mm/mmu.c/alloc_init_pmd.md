alloc_init_pmd
========================================

参数
----------------------------------------

path: arch/arm/mm/mmu.c
```
static void __init alloc_init_pmd(pud_t *pud, unsigned long addr,
                      unsigned long end, phys_addr_t phys,
                      const struct mem_type *type)
{
```

* pgd参数指定生成的页表的起始地址，它是一个pgd_t类型，被定义为typedef unsigned long pgd_t[2]，
  所以它是一个2维数组。

* addr和end分别指明被映射到的虚拟地址的起止地址。

* phys指明被映射的物理地址的起始地址。

* type参数指明映射类型，所有映射类型在struct mem_type mem_types[]数组中被统一定义。

pmd
----------------------------------------

```
    pmd_t *pmd = pmd_offset(pud, addr);
    unsigned long next;
```

对于arm平台来说通常只有两级页表，所以pmd == pud == pgd.

https://github.com/leeminghao/doc-linux/tree/master/4.x.y/arch/arm/include/asm/pgtable-2level.h/pmd_offset.md

pmd_addr_end
----------------------------------------

```
    do {
        /*
         * With LPAE, we must loop over to map
         * all the pmds for the given range.
         */
        next = pmd_addr_end(addr, end);
```

https://github.com/leeminghao/doc-linux/tree/master/4.x.y/include/asm-generic/pgtable.h/pmd_addr_end.md

生成页表项
----------------------------------------

首先根据公式(addr | end | phys) & ~SECTION_MASK) == 0依据传入的的addr，end和phys参数判断是否
满足地址对齐到1M。

```

        /*
         * Try a section mapping - addr, next and phys must all be
         * aligned to a section boundary.
         */
        if (type->prot_sect &&
                ((addr | next | phys) & ~SECTION_MASK) == 0) {
            __map_init_section(pmd, addr, next, phys, type);
        } else {
            alloc_init_pte(pmd, addr, next,
                        __phys_to_pfn(phys), type);
        }

        phys += next - addr;

    } while (pmd++, addr = next, addr != end);
}
```

### SECTION_MASK

https://github.com/leeminghao/doc-linux/tree/master/4.x.y/arch/arm/include/asm/pgtable-2level.h/SECTION_XXX.md

### __map_init_section

如果满足1MB对齐则直接生成主页表，并存入pgd指向的地址。

https://github.com/novelinux/linux-4.x.y/tree/master/arch/arm/mm/mmu.c/__map_init_section.md

### alloc_init_pte

如不满足1MB对齐直接生成主页表，那么调用alloc_init_pte生成二级页表。

https://github.com/novelinux/linux-4.x.y/tree/master/arch/arm/mm/mmu.c/alloc_init_pte.md
