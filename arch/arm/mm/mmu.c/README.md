MMU - page table
========================================

arm mmu的页表结构的通用框图:

https://github.com/leeminghao/doc-linux/blob/master/4.x.y/arch/arm/mm/mmu.c/res/mmu.jpg

以上是arm的页表框图的典型结构 - 即是二级页表结构.

当ARM要访问内存RAM时，MMU首先查找TLB中的虚拟地址表，如果ARM的结构支持分开的数据TLB和指令TLB，
那么它用：

* 取指令使用指令TLB
* 其它的所有访问类别用数据TLB

指令TLB和数据TLB在ARMv6架构的MMU中被分别称为指令MicroTLB和数据MicroTLB。如果没有命中MicroTLB，
那么将查询主TLB，此时不区分指令和数据TLB。

如果TLB中没有虚拟地址的入口，则转换表遍历硬件从存在主存储器中的页表中获取转换页表项，
它包含了物理地址或者二级页表地址和访问权限，一旦取到，这些信息将被放在TLB中，它会放在
一个没有使用的入口处或覆盖一个已有的入口。一旦为存储器访问的TLB 的入口被拿到,这些信息将被用于:

* C(高速缓存)和B(缓冲)位被用来控制高速缓存和写缓冲，并决定是否高速缓存。

* 首先检查域位，然后检查访问权限位用来控制访问是否被允许。如果不允许，则MMU 将向ARM处理器
  发送一个存储器异常；否则访问将被允许进行。

* 对没有或者禁止高速缓存的系统（包括在没有高速缓存系统中的所有存储器访问），物理地址将被用
  作主存储器访问的地址。

https://github.com/leeminghao/doc-linux/blob/master/4.x.y/arch/arm/mm/mmu.c/res/mmu_tlb_mm.jpg

其中第一级页表（L1）是由虚拟地址的高12bit（bits[31：20]）组成,所以第一级页表有4096个item，
每个item占4个字节，所以一级页表的大小为16KB，而在第一级页表中的每个entry的最低2bit可以用
来区分具体是什么种类的页表项，2bit可以区分4种页表项，具体每种页表项的结构如下：

https://github.com/leeminghao/doc-linux/blob/master/4.x.y/arch/arm/mm/mmu.c/res/page_item_category.png

简而言之L1页表的页表项主要有两大类:

* 直接指向1MB的物理内存。

在L1页表中每个表项可以覆盖1MB的内存，由于有4096K个选项（item），所以总计可以覆盖4096K*1MB=4GB
的内存空间。

* 指向第二级页表(L2页表)的基地址;

Linux page table
----------------------------------------

https://github.com/leeminghao/doc-linux/blob/master/4.x.y/mm/misc/page_table.md

ARM是2级的页表目录管理，事实上，只有PGD, PTE才是真正有意义的。

### __create_page_table

但在linux内核启动的初始化阶段，临时建立页表（initial page tables）以供linux内核初始化提供
执行环境，这时L1的页表项使用的就是第二种页表项（section enty），他直接映射的是1M的内存空间。

https://github.com/leeminghao/doc-linux/blob/master/4.x.y/arch/arm/kernel/head.S/__create_page_tables.md

针对这种section page translation，mmu硬件执行虚拟地址转物理地址的过程如下：

https://github.com/leeminghao/doc-linux/blob/master/4.x.y/arch/arm/mm/mmu.c/res/L1.png

### paging_init

以上在初始化过程使用的临时页表（initial page tables），在内核启动的后期会被覆盖掉即在
paging_init-->map_lowmem函数中会重新建立页表，该函数为物理内存从0地址到低端内存(lowmem_limit)
建立一个一一映射的映射表。所谓的一一映射就是物理地址和虚拟地址就差一个固定的偏移量，该偏移量
一般就是0xc0000000（呵呵，为什么是0xc0000000？）

说到这里引入一个重要的概念，就是与低端内存相对的高端内存，什么是高端内存？为什么需要高端内存？

https://github.com/leeminghao/doc-linux/blob/master/4.x.y/mm/misc/high_memory-low_memory.md

为了解析这个问题，我们假设我们使用的物理内存有2GB大小，另外由于我们内核空间的地址范围是从
3G-4G的空间，并且前面也说到了，linux内核的低端内存空间都是一一映射的，如果不引入高端内存这个概念，
全部都使用一一映射的方式，那内核只能访问到1GB的物理内存，但实际上，我们是需要内核在内核空间能够
访问所有的4GB的内存大小的，那怎么做到呢？

方法就是我们不让3G-4G的空间都使用一一映射，而是将物理地址的[0x00，fix_addr]（fix_addr<1GB）
映射到内核空间虚拟地址[0x00+3G，fix_addr+3G]，然后将[fix_addr+3G，4G]这段空间保留下来用于
动态映射，这样我们可以通过这段虚拟地址来访问从fix_addr到4GB的物理内存空间。怎么做到的呢？

譬如我们想要访问物理地址[fix_addr，4GB]这段区间中的任何一段，我就用宝贵的内核虚拟地址
[fix_addr+3G，4G]的一段去映射他，建立好mmu硬件使用的页表，访问完后，将映射清除，
将内核的这段虚拟地址释放，以供下次访问其他的物理内存使用。这样就可以达到访问所有4GB
的物理内存的目的。

arm mmu硬件是如何在二级页表结构中，实现虚拟地址转物理地址的.

https://github.com/leeminghao/doc-linux/blob/master/4.x.y/arch/arm/mm/mmu.c/res/L2.png

那么内核代码是如何建立映射表的呢？

https://github.com/leeminghao/doc-linux/blob/master/4.x.y/arch/arm/mm/mmu.c/paging_init.md

ARM 页表描述符
----------------------------------------

尽管Linux在多数系统上实现或者模拟了3级页表，但是在ARM Linux上它只实现了主页表和两级页表。
主页表通过ARM CPU的段表实现，段表中的每个页表项管理1M的内存，虚拟地址只需要一次转换既
可以得到物理地址，它通常存放在swapper_pg_dir开始的16K区域内。两级页表只有在被映射的
物理内存块不满足1M的情况下才被使用，此时它由L1和L2组成。

如下两种页表转换机制由CP15协处理器的控制寄存器c1中的bit23来选择。bit23为0时为兼容ARMv4和ARMv5,
否则为ARMv6。在CPU初始化后该位的默认值为0。Linux在系统引导时会设置MMU的控制寄存器的相关位，
其中把bit23设置为1，所以Linux在ARMv6体系架构上采用的是ARMv6 MMU页表转换机制。

### ARMv4 vs ARMv5

兼容ARMv4和ARMv5 MMU机制的页表描述符。这种描述符可以对64K大页面和4K小页面再进一步细分为子页面。

#### L1

https://github.com/leeminghao/doc-linux/blob/master/4.x.y/arch/arm/mm/mmu.c/res/pg_armv45_l1.jpg

#### L2

https://github.com/leeminghao/doc-linux/blob/master/4.x.y/arch/arm/mm/mmu.c/res/pg_armv45_l2.jpg

### ARMv6

#### L1

https://github.com/leeminghao/doc-linux/blob/master/4.x.y/arch/arm/mm/mmu.c/res/pg_armv6_l1.jpg

#### L2

https://github.com/leeminghao/doc-linux/blob/master/4.x.y/arch/arm/mm/mmu.c/res/pg_armv6_l2.jpg

页表计算
----------------------------------------

### 页目录(PGD)

https://github.com/leeminghao/doc-linux/blob/master/4.x.y/arch/arm/mm/mmu.c/create_mapping.md

#### 页目录项地址

页目录项地址的计算是通过宏pgd_offset_k来计算的，如下所示:

https://github.com/leeminghao/doc-linux/blob/master/4.x.y/arch/arm/include/asm/pgtable.h/pgd_offset_k.md

#### 页目录项值

页目录项值的计算是通过宏__pmd来计算的，如下所示:

https://github.com/leeminghao/doc-linux/blob/master/4.x.y/arch/arm/include/asm/pgtable-2level.h/README.md

#### 具体流程

https://github.com/leeminghao/doc-linux/blob/master/4.x.y/arch/arm/mm/mmu.c/__map_init_section.md

### 一级页表项(PMD)

#### 一级页表项地址

同页目录项地址

https://github.com/leeminghao/doc-linux/blob/master/4.x.y/arch/arm/include/asm/pgtable.h/pgd_offset_k.md

#### 一级页表项值

```
        pte_t *pte = early_alloc(PTE_HWTABLE_OFF + PTE_HWTABLE_SIZE);
        __pmd_populate(pmd, __pa(pte), prot);
```

https://github.com/leeminghao/doc-linux/blob/master/4.x.y/arch/arm/mm/mmu.c/early_pte_alloc.md

### 二级页表项(PTE)

#### 二级页表项地址

```
        pte_t *pte = early_alloc(PTE_HWTABLE_OFF + PTE_HWTABLE_SIZE);
```

https://github.com/leeminghao/doc-linux/blob/master/4.x.y/arch/arm/mm/mmu.c/early_alloc.md

#### 二级页表项值

```
pte = pte_offset_kernel(pmd, addr);
...
set_pte_ext(pte, pfn_pte(pfn, __pgprot(type->prot_pte)), 0);
```

https://github.com/leeminghao/doc-linux/blob/master/4.x.y/arch/arm/mm/mmu.c/alloc_init_pte.md
