mem_types
========================================

它定义了一个类型为struct mem_type的局部静态数组。根据不同的映射类型，它定义了不同的访问权限，
它通过md参数中的type成员传递给create_mapping

path: arch/arm/mm/mmu.c
```
static struct mem_type mem_types[] = {
    [MT_DEVICE] = {          /* Strongly ordered / ARMv6 shared device */
        .prot_pte    = PROT_PTE_DEVICE | L_PTE_MT_DEV_SHARED |
                       L_PTE_SHARED,
        .prot_pte_s2 = s2_policy(PROT_PTE_S2_DEVICE) |
                       s2_policy(L_PTE_S2_MT_DEV_SHARED) |
                       L_PTE_SHARED,
        .prot_l1    = PMD_TYPE_TABLE,
        .prot_sect    = PROT_SECT_DEVICE | PMD_SECT_S,
        .domain        = DOMAIN_IO,
    },
    [MT_DEVICE_NONSHARED] = { /* ARMv6 non-shared device */
        .prot_pte    = PROT_PTE_DEVICE | L_PTE_MT_DEV_NONSHARED,
        .prot_l1    = PMD_TYPE_TABLE,
        .prot_sect    = PROT_SECT_DEVICE,
        .domain        = DOMAIN_IO,
    },
    [MT_DEVICE_CACHED] = {      /* ioremap_cached */
        .prot_pte    = PROT_PTE_DEVICE | L_PTE_MT_DEV_CACHED,
        .prot_l1    = PMD_TYPE_TABLE,
        .prot_sect    = PROT_SECT_DEVICE | PMD_SECT_WB,
        .domain        = DOMAIN_IO,
    },
    [MT_DEVICE_WC] = {    /* ioremap_wc */
        .prot_pte    = PROT_PTE_DEVICE | L_PTE_MT_DEV_WC,
        .prot_l1    = PMD_TYPE_TABLE,
        .prot_sect    = PROT_SECT_DEVICE,
        .domain        = DOMAIN_IO,
    },
    [MT_UNCACHED] = {
        .prot_pte    = PROT_PTE_DEVICE,
        .prot_l1    = PMD_TYPE_TABLE,
        .prot_sect    = PMD_TYPE_SECT | PMD_SECT_XN,
        .domain        = DOMAIN_IO,
    },
    [MT_CACHECLEAN] = {
        .prot_sect = PMD_TYPE_SECT | PMD_SECT_XN,
        .domain    = DOMAIN_KERNEL,
    },
#ifndef CONFIG_ARM_LPAE
    [MT_MINICLEAN] = {
        .prot_sect = PMD_TYPE_SECT | PMD_SECT_XN | PMD_SECT_MINICACHE,
        .domain    = DOMAIN_KERNEL,
    },
#endif
    [MT_LOW_VECTORS] = {
        .prot_pte  = L_PTE_PRESENT | L_PTE_YOUNG | L_PTE_DIRTY |
                L_PTE_RDONLY,
        .prot_l1   = PMD_TYPE_TABLE,
        .domain    = DOMAIN_USER,
    },
    [MT_HIGH_VECTORS] = {
        .prot_pte  = L_PTE_PRESENT | L_PTE_YOUNG | L_PTE_DIRTY |
                L_PTE_USER | L_PTE_RDONLY,
        .prot_l1   = PMD_TYPE_TABLE,
        .domain    = DOMAIN_USER,
    },
    [MT_MEMORY_RWX] = {
        .prot_pte  = L_PTE_PRESENT | L_PTE_YOUNG | L_PTE_DIRTY,
        .prot_l1   = PMD_TYPE_TABLE,
        .prot_sect = PMD_TYPE_SECT | PMD_SECT_AP_WRITE,
        .domain    = DOMAIN_KERNEL,
    },
    [MT_MEMORY_RW] = {
        .prot_pte  = L_PTE_PRESENT | L_PTE_YOUNG | L_PTE_DIRTY |
                 L_PTE_XN,
        .prot_l1   = PMD_TYPE_TABLE,
        .prot_sect = PMD_TYPE_SECT | PMD_SECT_AP_WRITE,
        .domain    = DOMAIN_KERNEL,
    },
    [MT_ROM] = {
        .prot_sect = PMD_TYPE_SECT,
        .domain    = DOMAIN_KERNEL,
    },
    [MT_MEMORY_RWX_NONCACHED] = {
        .prot_pte  = L_PTE_PRESENT | L_PTE_YOUNG | L_PTE_DIRTY |
                L_PTE_MT_BUFFERABLE,
        .prot_l1   = PMD_TYPE_TABLE,
        .prot_sect = PMD_TYPE_SECT | PMD_SECT_AP_WRITE,
        .domain    = DOMAIN_KERNEL,
    },
    [MT_MEMORY_RW_DTCM] = {
        .prot_pte  = L_PTE_PRESENT | L_PTE_YOUNG | L_PTE_DIRTY |
                L_PTE_XN,
        .prot_l1   = PMD_TYPE_TABLE,
        .prot_sect = PMD_TYPE_SECT | PMD_SECT_XN,
        .domain    = DOMAIN_KERNEL,
    },
    [MT_MEMORY_RWX_ITCM] = {
        .prot_pte  = L_PTE_PRESENT | L_PTE_YOUNG | L_PTE_DIRTY,
        .prot_l1   = PMD_TYPE_TABLE,
        .domain    = DOMAIN_KERNEL,
    },
    [MT_MEMORY_RW_SO] = {
        .prot_pte  = L_PTE_PRESENT | L_PTE_YOUNG | L_PTE_DIRTY |
                L_PTE_MT_UNCACHED | L_PTE_XN,
        .prot_l1   = PMD_TYPE_TABLE,
        .prot_sect = PMD_TYPE_SECT | PMD_SECT_AP_WRITE | PMD_SECT_S |
                PMD_SECT_UNCACHED | PMD_SECT_XN,
        .domain    = DOMAIN_KERNEL,
    },
    [MT_MEMORY_DMA_READY] = {
        .prot_pte  = L_PTE_PRESENT | L_PTE_YOUNG | L_PTE_DIRTY |
                L_PTE_XN,
        .prot_l1   = PMD_TYPE_TABLE,
        .domain    = DOMAIN_KERNEL,
    },
};
```

struct mem_type
----------------------------------------

https://github.com/leeminghao/doc-linux/tree/master/4.x.y/arch/arm/mm/struct_mem_type.h

映射类型
----------------------------------------

* MT_MEMORY       - 对应RAM; MT_MEMORY被用来映射主存RAM。它只有段页表，
                    对应访问权限中的第二条:特权模式可以读写，用户模式禁止访问。
* MT_DEVICE       - 对应了其他I/O设备，应用于ioremap;
* MT_ROM          - 对应于ROM;
* MT_LOW_VECTORS  - 对应0地址开始的向量;
* MT_HIGH_VECTORS - 对应高地址开始的向量，它有vector_base宏决定.

访问控制属性
----------------------------------------

https://github.com/leeminghao/doc-linux/tree/master/4.x.y/arch/arm/include/asm/domain.h/domain.h.md
