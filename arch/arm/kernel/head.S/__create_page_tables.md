__create_page_tables
========================================

为kernel建立临时页表, kernel里面的所有符号在链接时，都使用了虚拟地址值。在完成基本的初始化后，
kernel代码将跳到第一个C语言函数start_kernl来执行，在哪个时候，这些虚拟地址必须能够对它所存放在
真正内存位置，否则运行将为出错。为此，CPU必须开启MMU，但在开启 MMU前，必须为虚拟地址到物理地址
的映射建立相应的页表。在开启MMU后，kernel指并不马上将PC值指向start_kernl，而是要做一些C语言运行
期的设置，如堆栈，重定义等工作后才跳到start_kernel去执行。在此过程中，PC值还是物理地址，因此还
需要为这段内存空间建立va = pa的内存映射关系。当然，本函数建立的所有页表都会在将来paging_init
销毁再重建，这是临时过度性的映射关系和页表。

计算页表起始物理地址保存到r4寄存器
----------------------------------------

path: arch/arm/kernel/head.S
```
#ifdef CONFIG_ARM_LPAE
...
#else
#define PG_DIR_SIZE 0x4000
#define PMD_ORDER   2
#endif

    ...
    .macro    pgtbl, rd, phys
    add    \rd, \phys, #TEXT_OFFSET - PG_DIR_SIZE
    .endm
    ...
/*
 * Setup the initial page tables.  We only setup the barest
 * amount which are required to get the kernel running, which
 * generally means mapping in the kernel code.
 *
 * r8 = phys_offset, r9 = cpuid, r10 = procinfo
 *
 * Returns:
 *  r0, r3, r5-r7 corrupted
 *  r4 = physical page table address
 */
__create_page_tables:
    pgtbl    r4, r8                @ page table address
```

r8寄存器保存的是物理内存的起始地址(在这里我们是0x80200000),TEXT_OFFSET是0x8000, PG_DIR_SIZE是
0x4000，根据宏pgtbl计算得到的页表起始地址为0x80204000,而kernel image起始地址为0x80208000,
即页表是存放在kernel其实地址下16KB的地方(0x80204000 ~ 0x80208000 | 0xc0004000 ~ 0xc0008000).

清空16KB页表空间
----------------------------------------

```
    ...

    /*
     * Clear the swapper page table
     */
    mov    r0, r4
    mov    r3, #0
    add    r6, r0, #PG_DIR_SIZE
1:  str    r3, [r0], #4
    str    r3, [r0], #4
    str    r3, [r0], #4
    str    r3, [r0], #4
    teq    r0, r6
    bne    1b
```

读取proc_info_list的成员__cpu_mm_mmu_flags保存到r7寄存器
----------------------------------------

r10 = proc_info_list类型结构体的基地址.
PROCINFO_MM_MMUFLAGS 8 /* offsetof(struct proc_info_list, __cpu_mm_mmu_flags)

```
    ldr    r7, [r10, #PROCINFO_MM_MMUFLAGS] @ mm_mmuflags
```

首先建立包含__turn_mmu_on函数1M空间的平映射(virt addr = phy addr)
----------------------------------------

```
    /*
     * Create identity mapping to cater for __enable_mmu.
     * This identity mapping will be removed by paging_init().
     */
    adr    r0, __turn_mmu_on_loc
    ldmia  r0, {r3, r5, r6}
    /* 计算函数__turn_mmu_on和__turn_mmu_on_end函数的物理地址. */
    sub    r0, r0, r3            @ virt->phys offset
    add    r5, r5, r0            @ phys __turn_mmu_on
    add    r6, r6, r0            @ phys __turn_mmu_on_end
    /* 因1页(4KB)映射1M空间，所以SECTION_SHIFT为20, 右移20位后，
     * r5，r6代表该段地址空间的物理地址(页内偏移值)*/
    mov    r5, r5, lsr #SECTION_SHIFT
    mov    r6, r6, lsr #SECTION_SHIFT

    /* r5左移20位，获取该页基地址，或上CPU的mmuflags，存在r3中 */
1:  orr    r3, r7, r5, lsl #SECTION_SHIFT    @ flags + kernel base
    /* 将r3值存储在页目录表空间（r4起始）的（r5<<2）的页表中, 因一页用4bytes表示，所以PMD_ORDER=2 */
    str    r3, [r4, r5, lsl #PMD_ORDER]    @ identity mapping
    /* r5与r6之前相距多个1M，则需要填写多个页表。
     * 因turn_mmu_on函数很短，所以肯定在1M内，该处r5=r6 */
    cmp    r5, r6
    addlo  r5, r5, #1            @ next section
    blo    1b
    ...

    .ltorg
    .align
__turn_mmu_on_loc:
    .long    .
    .long    __turn_mmu_on
    .long    __turn_mmu_on_end
```

建立kernel image镜像的映射
----------------------------------------

接下来以多个1M的线性映射页表，建立kernel整个镜像的线性映射，这里有一个小技巧，利用当前
PC值作为内核物理地址起始，create_page_tables距离内核起始地址不超过1MB，因此移位之后就是
内核起始的物理页号。arm的create_page_tables中，不管是turn_mmu_on还是这里，都是使用的当前
pc值计算物理页号，这样的好处是，不管内核加载到什么物理地址，都可以迅速的建立正确的页表映射。
并且不需要内核开发人员对这部分代码进行修改

```
/*
 * swapper_pg_dir is the virtual address of the initial page table.
 * We place the page tables 16K below KERNEL_RAM_VADDR.  Therefore, we must
 * make sure that KERNEL_RAM_VADDR is correctly set.  Currently, we expect
 * the least significant 16 bits to be 0x8000, but we could probably
 * relax this restriction to KERNEL_RAM_VADDR >= PAGE_OFFSET + 0x4000.
 */
#define KERNEL_RAM_VADDR (PAGE_OFFSET + TEXT_OFFSET)
#if (KERNEL_RAM_VADDR & 0xffff) != 0x8000
#error KERNEL_RAM_VADDR must start at 0xXXXX8000
#endif

#ifdef CONFIG_XIP_KERNEL
...
#else
#define KERNEL_START KERNEL_RAM_VADDR // 0xC0008000
#define KERNEL_END   _end
#endif

    /*
     * Now setup the pagetables for our kernel direct
     * mapped region.
     */
    /* 计算当前kernel运行的物理地址所在物理页面的起始地址 */
    mov    r3, pc
    mov    r3, r3, lsr #SECTION_SHIFT
    orr    r3, r7, r3, lsl #SECTION_SHIFT

    /* 因为KERNEL_START是内核的起始虚拟地址(0xC0008000)，KERNEL_END为内核的结束虚拟地址，
     * 所以下面的代码实际上是将物理地址为kernel的起始地址(0x80208000)的一段内存空间
     * (大小为内核映像文件的大小)映射到虚拟地址0xC0008000。*/
    add    r0, r4,  #(KERNEL_START & 0xff000000) >> (SECTION_SHIFT - PMD_ORDER)
    str    r3, [r0, #((KERNEL_START & 0x00f00000) >> SECTION_SHIFT) << PMD_ORDER]!
    ldr    r6, =(KERNEL_END - 1)
    add    r0, r0, #1 << PMD_ORDER
    add    r6, r4, r6, lsr #(SECTION_SHIFT - PMD_ORDER)
1:  cmp    r0, r6
    add    r3, r3, #1 << SECTION_SHIFT
    strls  r3, [r0], #1 << PMD_ORDER
    bls    1b
```

建立atags的映射
----------------------------------------

```
    /*
     * Then map boot params address in r2 or the first 1MB (2MB with LPAE)
     * of ram if boot params address is not specified.
     */
    // 将atags的1M地址空间做线性映射，方便start_kernel中对args进行分析
    mov    r0, r2, lsr #SECTION_SHIFT
    movs   r0, r0, lsl #SECTION_SHIFT
    moveq  r0, r8
    sub    r3, r0, r8
    add    r3, r3, #PAGE_OFFSET
    add    r3, r4, r3, lsr #(SECTION_SHIFT - PMD_ORDER)
    orr    r6, r7, r0
    str    r6, [r3]
    ...

    mov    pc, lr
ENDPROC(__create_page_tables)
```

create_page_table完成了3种地址映射的页表空间填写：
* turn_mmu_on所在1M空间的平映射
* kernel image的线性映射
* atags所在1M空间的线性映射

https://github.com/novelinux/linux-4.x.y/tree/master/arch/arm/kernel/head.S/res/map.jpg

问题
----------------------------------------

* 1.为什么turn_mmu_on要做平映射？

turn_mmu_on，主要是完成开启MMU的操作。那为什么将turn_mmu_on处做一个平映射？
可以想象，执行开启MMU指令之前，CPU取指是在0x80208000附近turn_mmu_on中。
如果只是做kernel image的线性映射，执行开启MMU指令后，CPU所看到的地址就全变啦。
turn_mmu_on对于CPU来说在0xc0008000附近，0x80208000附近对于CPU来说已经不可预知了。
但是CPU不知道这些，它只管按照地址一条条取指令，执行指令。所以不做turn_mmu_on的平映射
(virt addr = phy addr)，turn_mmu_on在开启MMU后的运行是完全不可知。完成turn_mmu_on的平映射，
我们可以在turn_mmu_on末尾MMU已经开启稳定后，修改PC到0xc0008000附近，就可以解决从
0x8xxxxxxx到0xcxxxxxxx的跳转。

* 2.kernel image加载地址为什么会在0x****8000？

分析了kernel image线性映射部分，这个就好理解了，kernel编译链接时的入口地址在0xc0008000
(PAGE_OFFSET + TEXT_OFFSET)，但其物理地址不等于其链接的虚拟地址，image的线性映射实现其
运行地址等于链接地址。kernel的每一页表映射1M，所以入口处在(0x80200000-->0xc0000000)
映射页表中完成映射。物理地址和虚拟地址的1M内偏移必须一致呀。kernel定义的
TEXT_OFFSET = 0x8000.所以加载的物理地址必须为0x****8000. 这样，开启MMU后，
访问0xc0008000附近指令，MMU根据TLB才能正确映射找到0x****8000附近的指令。

* 3.atags跟kernel入口是在同一1M空间内，bootparams的线性映射操作是否多余？

根据第二个问题的分析，kernel image可以加载到任何sdram地址空间的0x****8000即可。
atags地址是有bootloader中指定，然后告诉kernel。那就有这样一种情况，加入sdram
起始地址为0x80200000，atags起始地址为0x80200100。但kernel image我加载到0x81008000，
可以看出，这时atags跟kernel image就在不同一1M空间啦atags单独的线性映射操作还是很有必要的。

参考资料
----------------------------------------

有关ARM一级页表的相关信息如下所示:

https://github.com/novelinux/linux-4.x.y/tree/master/arch/arm/mm/mmu.c/res/L1.png
