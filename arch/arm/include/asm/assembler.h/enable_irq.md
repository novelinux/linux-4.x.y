enable_irq
========================================

path: arch/arm/include/asm/assembler.h
```
/*
 * Enable and disable interrupts
 * CPSID   CPSIE  用于快速的开关中断。
 */
#if __LINUX_ARM_ARCH__ >= 6
    .macro disable_irq_notrace
    cpsid i
    .endm

    .macro enable_irq_notrace
    @保存完上下文后才使能中断,
    cpsie i
    .endm
#else
        ...
#endif
        ...
    .macro enable_irq
    asm_trace_hardirqs_on
    enable_irq_notrace
    .endm
```

* CPSID I PRIMASK=1 关中断
* CPSIE I PRIMASK=0 开中断
* CPSID F FAULTMASK=1 关异常
* CPSIE F FAULTMASK=0 开异常

I: IRQ F: FIQ
