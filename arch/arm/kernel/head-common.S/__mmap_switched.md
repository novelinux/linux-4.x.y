__mmap_switched
========================================

path: arch/arm/kernel/head-common.S
```
/*
 * The following fragment of code is executed with the MMU on in MMU mode,
 * and uses absolute addresses; this is not position independent.
 *
 *  r0  = cp#15 control register
 *  r1  = machine ID
 *  r2  = atags/dtb pointer
 *  r9  = processor ID
 */
    __INIT
__mmap_switched:
    adr    r3, __mmap_switched_data

    ldmia  r3!, {r4, r5, r6, r7}

    /* 如果有必要则进行data段的拷贝搬移 */
    cmp    r4, r5                @ Copy data segment if needed
1:  cmpne  r5, r6
    ldrne  fp, [r4], #4
    strne  fp, [r5], #4
    bne    1b

    /* 清空bss段 */
    mov    fp, #0                @ Clear BSS (and zero fp)
1:  cmp    r6, r7
    strcc  fp, [r6],#4
    bcc    1b

 ARM(    ldmia    r3, {r4, r5, r6, r7, sp})
 THUMB(    ldmia    r3, {r4, r5, r6, r7}    )
 THUMB(    ldr    sp, [r3, #16]        )

    /* 保存处理器ID atag地址等到指定全局变量中，设置SP，跳转到start_kernel */
    str    r9, [r4]            @ Save processor ID
    str    r1, [r5]            @ Save machine type
    str    r2, [r6]            @ Save atags pointer
    bic    r4, r0, #CR_A            @ Clear 'A' bit
    stmia  r7, {r0, r4}            @ Save control register values
    b    start_kernel
ENDPROC(__mmap_switched)

    .align    2
    .type    __mmap_switched_data, %object
__mmap_switched_data:
    .long    __data_loc            @ r4
    .long    _sdata                @ r5
    .long    __bss_start            @ r6
    .long    _end                @ r7
    .long    processor_id            @ r4
    .long    __machine_arch_type        @ r5
    .long    __atags_pointer            @ r6
    .long    cr_alignment            @ r7
    .long    init_thread_union + THREAD_START_SP @ sp
    .size    __mmap_switched_data, . - __mmap_switched_data
```

sp = init_thread_union + THREAD_START_SP(8K-8)，设置栈指针，为接下来的C函数运行做准备。
对于arm-linux来说，start_kernel之前全部都是汇编代码。init_thread_union代表的是
内核第一个进程，pid = 0，该进程是内核人为造出来的，而不是fork出来的.

https://github.com/leeminghao/doc-linux/blob/master/4.x.y/arch/arm/kernel/init_task.c/README.md

__mmap_switched最后跳转到start_kernel开始进入C函数运行环境，这时整个kernel image
已经运行在虚拟地址之上，运行地址和链接地址保持了一致.

https://github.com/leeminghao/doc-linux/blob/master/4.x.y/init/main.c/start_kernel.md
