swapper_pg_dir
========================================

path: arch/arm/kernel/head.S
```
/*
 * swapper_pg_dir is the virtual address of the initial page table.
 * We place the page tables 16K below KERNEL_RAM_VADDR.  Therefore, we must
 * make sure that KERNEL_RAM_VADDR is correctly set.  Currently, we expect
 * the least significant 16 bits to be 0x8000, but we could probably
 * relax this restriction to KERNEL_RAM_VADDR >= PAGE_OFFSET + 0x4000.
 */
#define KERNEL_RAM_VADDR    (PAGE_OFFSET + TEXT_OFFSET)
#if (KERNEL_RAM_VADDR & 0xffff) != 0x8000
#error KERNEL_RAM_VADDR must start at 0xXXXX8000
#endif

#ifdef CONFIG_ARM_LPAE
    /* LPAE requires an additional page for the PGD */
#define PG_DIR_SIZE  0x5000
#define PMD_ORDER    3
#else
#define PG_DIR_SIZE  0x4000
#define PMD_ORDER    2
#endif

    .globl  swapper_pg_dir
    .equ    swapper_pg_dir, KERNEL_RAM_VADDR - PG_DIR_SIZE
```

swapper_pg_dir在head.S中被定义为PAGE_OFFSET向上偏移TEXT_OFFSET。TEXT_OFFSET代表内核代码段的相对于
PAGE_OFFSET的偏移。KERNEL_RAM_VADDR的值与_stext的值相同，代表了内核代码的起始地址。swapper_pg_dir
为KERNEL_RAM_VADDR - 0x4000，也即向低地址方向偏移了16K。

ARM Linux中的主内存页表，使用段表。每个页表映射1M的内存大小，由于16K / 4 * 1M = 4G，这16K的
主页表空间正好映射4G的虚拟空间。内核页表机制在系统启动过程中的paging_init函数中使能，其中对
内核主页表的初始化等操作均是通过init_mm.pgd的引用来进行的。

经过上述计算得到swapper_pg_dir的虚拟地址为0xc0004000.