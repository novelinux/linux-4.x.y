alloc_init_pte
========================================

alloc_init_pte在初始化非主RAM中起到重要的作用，它尝试创建二级页表。二级页表的L1实际上还是存在于
主页表(pgd)中，只不过此时的主页表项不再是物理地址，而是二级页表，或者称为中间页表(PMD)。

参数
----------------------------------------

path: arch/arm/mm/mmu.c
```
static void __init alloc_init_pte(pmd_t *pmd, unsigned long addr,
                  unsigned long end, unsigned long pfn,
                  const struct mem_type *type)
{
```

* pmd - 参数传递L1页表地址。
* addr和end - 分别指明被映射到的虚拟地址的起止地址。
* pfn - 是将被映射的物理地址的页框。
* type - 参数指明映射类型。

early_pte_alloc
----------------------------------------

pte: 页表条目 (Page Table Entry)，即pte，是页表的最低层，它直接处理页，该值包含某页的物理地址，
还包含了说明该条目是否有效及相关页是否在物理内存中的位。

early_pte_alloc函数判断对应的pmd所指向的L2(PTE)页表是否存在，如果不存在就分配L2(PTE)页表，
最后返回虚拟地址addr在PTE页表中对应的页表项的虚拟地址.

```
    pte_t *pte = early_pte_alloc(pmd, addr, type->prot_l1);
```

https://github.com/novelinux/linux-4.x.y/tree/master/arch/arm/mm/mmu.c/early_pte_alloc.md

set_pte_ext
----------------------------------------

```
    do {
        // 设置L2页表中addr所定位到的页表项(pte), 主要工作就是填充对应物理页的物理地址,
        // 以供mmu硬件来实现地址的翻译。
        set_pte_ext(pte, pfn_pte(pfn, __pgprot(type->prot_pte)), 0);
        pfn++;
    // 循环填充完两个hwpte页表，完成一个2M物理内存的映射表的建立。
    } while (pte++, addr += PAGE_SIZE, addr != end);
}
```

https://github.com/novelinux/linux-4.x.y/tree/master/arch/arm/include/asm/pgtable-2level.h/set_pte_ext.md
