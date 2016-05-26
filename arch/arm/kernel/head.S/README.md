head.S 内核启动
========================================

zImage由其头部的解压程序将真正的内核代码解压到zreladdr地址处后，将跳转到改地址执行
真正的内核代码, 相应的解压过程如下所示:

https://github.com/novelinux/linux-4.x.y/tree/master/arch/arm/boot/compressed/head.S/README.md

Code Flow
----------------------------------------

```
        stext
          |
__lookup_processor_type
          |
     __vet_atags
          |
  __create_page_tables
          |
      __v7_setup
          |
     __enable_mmu
          |
    __mmap_switched
          |
     start_kernel
```

内核入口
----------------------------------------

path: arch/arm/kernel/vmlinux.ld.S
```
OUTPUT_ARCH(arm)
ENTRY(stext)

#ifndef __ARMEB__
jiffies = jiffies_64;
#else
jiffies = jiffies_64 + 4;
#endif

SECTIONS
{
#ifdef CONFIG_XIP_KERNEL
    . = XIP_VIRT_ADDR(CONFIG_XIP_PHYS_ADDR);
#else
    . = PAGE_OFFSET + TEXT_OFFSET; /* 0xC0008000 */
#endif
    .head.text : {
        _text = .;
        HEAD_TEXT
    }
#ifdef CONFIG_STRICT_MEMORY_RWX
    . = ALIGN(1<<SECTION_SHIFT);
#endif

    .text : {            /* Real text segment        */
        _stext = .;        /* Text and read-only data    */
                ...
    }

        ...

    _etext = .;            /* End of text and rodata section */
        ...
```

内核的入口是stext, 这里的ENTRY(stext) 表示程序的入口是在符号stext.
而符号stext是在arch/arm/kernel/head.S中定义的.

有关linker script的详细解释如下:

https://github.com/novelinux/linux-4.x.y/tree/master/arch/arm/kernel/vmlinux.lds.S/README.md

```
/*
 * Kernel startup entry point.
 * ---------------------------
 *
 * This is normally called from the decompressor code.  The requirements
 * are: MMU = off, D-cache = off, I-cache = dont care, r0 = 0,
 * r1 = machine nr, r2 = atags or dtb pointer.
 *
 * This code is mostly position independent, so if you link the kernel at
 * 0xc0008000, you call this at __pa(0xc0008000).
 *
 * See linux/arch/arm/tools/mach-types for the complete list of machine
 * numbers for r1.
 *
 * We're trying to keep crap to a minimum; DO NOT add any machine specific
 * crap here - that's what the boot loader (or in extreme, well justified
 * circumstances, zImage) is for.
 */
    .arm

    __HEAD
ENTRY(stext)
```

相关地址值
----------------------------------------

https://github.com/torvalds/linux/blob/bdec41963890f8ed9ad89f8b418959ab3cdc2aa3/Documentation/arm/Porting

* PHYS_OFFSET

https://github.com/novelinux/linux-4.x.y/tree/master/arch/arm/include/asm/memory.h/PHYS_OFFSET.md

* PAGE_OFFSET

https://github.com/novelinux/linux-4.x.y/tree/master/arch/arm/include/asm/memory.h/PAGE_OFFSET.md

* TEXT_OFFSET

https://github.com/novelinux/linux-4.x.y/tree/master/arch/arm/Makefile/TEXT_OFFSET

流程
----------------------------------------

path: arch/arm/kernel/head.S

#### 检查kernel是ARM模式还是thum模式.

```
ENTRY(stext)

 THUMB(    adr    r9, BSYM(1f)    )    @ Kernel is always entered in ARM.
 THUMB(    bx    r9        )    @ If this is a Thumb-2 kernel,
 THUMB(    .thumb            )    @ switch to Thumb now.
 THUMB(1:            )
```

#### 2.确保kernel是运行在svc模式下的，并且IRQ和FIRQ中断已经关闭.

```
    setmode    PSR_F_BIT | PSR_I_BIT | SVC_MODE, r9 @ ensure svc mode
                        @ and irqs disabled
```

#### 确定processor id.

```
    mrc    p15, 0, r9, c0, c0        @ get processor id
    bl    __lookup_processor_type        @ r5=procinfo r9=cpuid
    movs    r10, r5                @ invalid processor (r5=0)?
 THUMB( it    eq )        @ force fixup-able long branch encoding
    beq    __error_p            @ yes, error 'p'
```

https://github.com/novelinux/linux-4.x.y/tree/master/arch/arm/kernel/head-common.S/__lookup_processor_type.md

#### 计算内存RAM的起始物理地址phys_offset保存到r8寄存器.

* CONFIG_XIP_KERNEL
  Execute-In-Place allows the kernel to run from non-volatile storage directly
  addressable by the CPU, such as NOR flash. This saves RAM space since the
  text section of the kernel is not loaded from flash to RAM. Read-write
  sections, such as the data section and stack, are still copied to RAM.
  The XIP kernel is not compressed since it has to run directly from flash,
  so it will take more space to store it. The flash address used to link the
  kernel object files, and for storing it, is configuration dependent.
  Therefore, if you say Y here, you must know the proper physical address where
  to store the kernel image depending on your own flash memory usage.

```
#ifndef CONFIG_XIP_KERNEL
    adr    r3, 2f /* r3寄存器中保存标号2处的物理地址值 */
    ldmia    r3, {r4, r8} /* r4保存标号2处的虚拟地址值，r8保存PAGE_OFFSET值 */
        /* 计算RAM物理地址和虚拟地址的偏移值 --> r4 */
    sub    r4, r3, r4            @ (PHYS_OFFSET - PAGE_OFFSET)
    add    r8, r8, r4            @ PHYS_OFFSET
#else
    ldr    r8, =PHYS_OFFSET        @ always constant in this case
#endif
        ...
    .ltorg
#ifndef CONFIG_XIP_KERNEL
2:    .long    .
    .long    PAGE_OFFSET // 0xC0000000
#endif
```

#### 调用__vet_atags函数检查atags参数有效性.

```
    /*
     * r1 = machine no, r2 = atags or dtb,
     * r8 = phys_offset, r9 = cpuid, r10 = procinfo
     */
    bl    __vet_atags
```

https://github.com/novelinux/linux-4.x.y/tree/master/arch/arm/kernel/head-common.S/__vet_atags.md

#### 创建初始化页表

```
    bl    __create_page_tables
```

https://github.com/novelinux/linux-4.x.y/tree/master/arch/arm/kernel/head.S/__create_page_tables.md

#### 保存__mmap_switched虚拟地址到sp寄存器

建立初始化页表以后，会首先将__mmap_switched这个symbol的链接地址放在sp里面，
然后会跳到__proc_info_list里面的INITFUNC执行.这个偏移是定义在arch/arm/kernel/asm-offset.c里面，
实际上就是取得__proc_info_list里面的__cpu_flush这个函数执行。

```
    /*
     * The following calls CPU specific code in a position independent
     * manner.  See arch/arm/mm/proc-*.S for details.  r10 = base of
     * xxx_proc_info structure selected by __lookup_processor_type
     * above.  On return, the CPU will be ready for the MMU to be
     * turned on, and r0 will hold the CPU control register value.
     */
        /* r13中存下__mmap_switched地址，需要注意的是该地址是VMA(虚拟地址) */
    ldr    r13, =__mmap_switched        @ address to jump to after
                        @ mmu has been enabled

    adr    lr, BSYM(1f)            @ return (PIC) address

        /* 对于ARM指令(不是THUMB指令)，跳转到对应芯片结构的__cpu_flush执行 */
    mov    r8, r4                @ set TTBR1 to swapper_pg_dir
 ARM(    add    pc, r10, #PROCINFO_INITFUNC    )
 THUMB(    add    r12, r10, #PROCINFO_INITFUNC    )
 THUMB(    mov    pc, r12                )
```

proc-v7.S中分析过，__v7_proc_info中使用__v7_proc宏定义定义了其中的一些成员变量，
其中__cpu_flush=__v7_setup.__v7_setup在proc-v7.S中定义如下：

https://github.com/novelinux/linux-4.x.y/tree/master/arch/arm/mm/proc-v7.S/__v7_setup.md

__v7_setup执行完毕，回到stext，接下来跳转到__enable_mmu.

#### 打开MMU

打开MMU以后我们就可以使用虚拟地址了，而不需要我们自己来进行地址的重定位，ARM硬件会完成这部分
的工作。打开MMU以后，会将SP的值赋给PC，这样代码就会跳到__mmap_switched处执行的。

```
1:    b    __enable_mmu
ENDPROC(stext)
```

https://github.com/novelinux/linux-4.x.y/tree/master/arch/arm/kernel/head.S/__enable_mmu.md

__mmap_switched
----------------------------------------

在打开MMU后就要跳转到__mmap_switched函数中去执行:

https://github.com/novelinux/linux-4.x.y/tree/master/arch/arm/kernel/head-common.S/__mmap_switched.md
