__v7_setup
========================================

__v7_setup用来配置与armv7平台相关的MMU和页表相关信息.配置完毕后才能enable MMU.
其在内核启动过程中被调用.

https://github.com/novelinux/linux-4.x.y/tree/master/arch/arm/kernel/head.S/README.md

完成的主要工作如下：

* 刷新cache，v7_flush_dcache_all
* 无效cache
* 无效掉指令和数据TLB
* 从CP15 c0寄存器读出到r0，进行处理，做为下一步写入CP15 c0的值.

__v7_setup
----------------------------------------

path: arch/arm/mm/proc-v7.S
```
/*
 *    __v7_setup
 *
 *    Initialise TLB, Caches, and MMU state ready to switch the MMU
 *    on.  Return in r0 the new CP15 C1 control register setting.
 *
 *    This should be able to cover all ARMv7 cores.
 *
 *    It is assumed that:
 *    - cache type register is implemented
 */
__v7_ca5mp_setup:
__v7_ca9mp_setup:
    mov    r10, #(1 << 0)            @ TLB ops broadcasting
    b    1f
__v7_ca7mp_setup:
__v7_ca15mp_setup:
    mov    r10, #0
1:
#ifdef CONFIG_SMP
    ALT_SMP(mrc    p15, 0, r0, c1, c0, 1)
    ALT_UP(mov    r0, #(1 << 6))        @ fake it for UP
    tst    r0, #(1 << 6)            @ SMP/nAMP mode enabled?
    orreq    r0, r0, #(1 << 6)        @ Enable SMP/nAMP mode
    orreq    r0, r0, r10            @ Enable CPU-specific SMP bits
    mcreq    p15, 0, r0, c1, c0, 1
#endif
__v7_setup:
    adr    r12, __v7_setup_stack        @ the local stack
    stmia    r12, {r0-r5, r7, r9, r11, lr}
    bl    v7_flush_dcache_all
    ldmia    r12, {r0-r5, r7, r9, r11, lr}

    mrc    p15, 0, r0, c0, c0, 0        @ read main ID register
    and    r10, r0, #0xff000000        @ ARM?
    teq    r10, #0x41000000
    bne    3f
    and    r5, r0, #0x00f00000        @ variant
    and    r6, r0, #0x0000000f        @ revision
    orr    r6, r6, r5, lsr #20-4        @ combine variant and revision
    ubfx    r0, r0, #4, #12            @ primary part number

    /* Cortex-A8 Errata */
    ldr    r10, =0x00000c08        @ Cortex-A8 primary part number
    teq    r0, r10
    bne    2f
#ifdef CONFIG_ARM_ERRATA_430973
    teq    r5, #0x00100000            @ only present in r1p*
    mrceq    p15, 0, r10, c1, c0, 1        @ read aux control register
    orreq    r10, r10, #(1 << 6)        @ set IBE to 1
    mcreq    p15, 0, r10, c1, c0, 1        @ write aux control register
#endif
#ifdef CONFIG_ARM_ERRATA_458693
    teq    r6, #0x20            @ only present in r2p0
    mrceq    p15, 0, r10, c1, c0, 1        @ read aux control register
    orreq    r10, r10, #(1 << 5)        @ set L1NEON to 1
    orreq    r10, r10, #(1 << 9)        @ set PLDNOP to 1
    mcreq    p15, 0, r10, c1, c0, 1        @ write aux control register
#endif
#ifdef CONFIG_ARM_ERRATA_460075
    teq    r6, #0x20            @ only present in r2p0
    mrceq    p15, 1, r10, c9, c0, 2        @ read L2 cache aux ctrl register
    tsteq    r10, #1 << 22
    orreq    r10, r10, #(1 << 22)        @ set the Write Allocate disable bit
    mcreq    p15, 1, r10, c9, c0, 2        @ write the L2 cache aux ctrl register
#endif
    b    3f

    /* Cortex-A9 Errata */
2:    ldr    r10, =0x00000c09        @ Cortex-A9 primary part number
    teq    r0, r10
    bne    3f
#ifdef CONFIG_ARM_ERRATA_742230
    cmp    r6, #0x22            @ only present up to r2p2
    mrcle    p15, 0, r10, c15, c0, 1        @ read diagnostic register
    orrle    r10, r10, #1 << 4        @ set bit #4
    mcrle    p15, 0, r10, c15, c0, 1        @ write diagnostic register
#endif
#ifdef CONFIG_ARM_ERRATA_742231
    teq    r6, #0x20            @ present in r2p0
    teqne    r6, #0x21            @ present in r2p1
    teqne    r6, #0x22            @ present in r2p2
    mrceq    p15, 0, r10, c15, c0, 1        @ read diagnostic register
    orreq    r10, r10, #1 << 12        @ set bit #12
    orreq    r10, r10, #1 << 22        @ set bit #22
    mcreq    p15, 0, r10, c15, c0, 1        @ write diagnostic register
#endif
#ifdef CONFIG_ARM_ERRATA_743622
    teq    r5, #0x00200000            @ only present in r2p*
    mrceq    p15, 0, r10, c15, c0, 1        @ read diagnostic register
    orreq    r10, r10, #1 << 6        @ set bit #6
    mcreq    p15, 0, r10, c15, c0, 1        @ write diagnostic register
#endif
#if defined(CONFIG_ARM_ERRATA_751472) && defined(CONFIG_SMP)
    ALT_SMP(cmp r6, #0x30)            @ present prior to r3p0
    ALT_UP_B(1f)
    mrclt    p15, 0, r10, c15, c0, 1        @ read diagnostic register
    orrlt    r10, r10, #1 << 11        @ set bit #11
    mcrlt    p15, 0, r10, c15, c0, 1        @ write diagnostic register
1:
#endif

3:    mov    r10, #0
    mcr    p15, 0, r10, c7, c5, 0        @ I+BTB cache invalidate
    dsb
#ifdef CONFIG_MMU
    mcr    p15, 0, r10, c8, c7, 0        @ invalidate I + D TLBs
    v7_ttb_setup r10, r4, r8, r5        @ TTBCR, TTBRx setup
    ldr    r5, =PRRR            @ PRRR
    ldr    r6, =NMRR            @ NMRR
    mcr    p15, 0, r5, c10, c2, 0        @ write PRRR
    mcr    p15, 0, r6, c10, c2, 1        @ write NMRR
#endif

#if defined(CONFIG_ARCH_MSM_SCORPION) && !defined(CONFIG_MSM_SMP)
    mov     r0, #0x33
    mcr     p15, 3, r0, c15, c0, 3          @ set L2CR1
#endif
#if defined (CONFIG_ARCH_MSM_SCORPION)
    mrc     p15, 0, r0, c1, c0, 1           @ read ACTLR
#ifdef CONFIG_CPU_CACHE_ERR_REPORT
    orr     r0, r0, #0x37                   @ turn on L1/L2 error reporting
#else
    bic     r0, r0, #0x37
#endif
#if defined (CONFIG_ARCH_MSM_SCORPIONMP)
    orr    r0, r0, #0x1 << 24     @ optimal setting for Scorpion MP
#endif
#ifndef CONFIG_ARCH_MSM_KRAIT
    mcr     p15, 0, r0, c1, c0, 1           @ write ACTLR
#endif
#endif
#if defined (CONFIG_ARCH_MSM_SCORPIONMP)
    mrc     p15, 3, r0, c15, c0, 2  @ optimal setting for Scorpion MP
    orr         r0, r0, #0x1 << 21
    mcr     p15, 3, r0, c15, c0, 2
#endif

#ifndef CONFIG_ARM_THUMBEE
    mrc    p15, 0, r0, c0, c1, 0        @ read ID_PFR0 for ThumbEE
    and    r0, r0, #(0xf << 12)        @ ThumbEE enabled field
    teq    r0, #(1 << 12)            @ check if ThumbEE is present
    bne    1f
    mov    r5, #0
    mcr    p14, 6, r5, c1, c0, 0        @ Initialize TEEHBR to 0
    mrc    p14, 6, r0, c0, c0, 0        @ load TEECR
    orr    r0, r0, #1            @ set the 1st bit in order to
    mcr    p14, 6, r0, c0, c0, 0        @ stop userspace TEEHBR access
1:
#endif
```

### v7_crval

v7_crval定义了三个常量.

```
    adr    r5, v7_crval
```

https://github.com/novelinux/linux-4.x.y/tree/master/arch/arm/mm/proc-v7-2level.S/v7_crval.md

### set cp15

```
    # r5 - clear
    # r6 - mmuset
    ldmia    r5, {r5, r6}
#ifdef CONFIG_CPU_ENDIAN_BE8
    orr    r6, r6, #1 << 25        @ big-endian page tables
#endif
#ifdef CONFIG_SWP_EMULATE
    orr     r5, r5, #(1 << 10)              @ set SW bit in "clear"
    bic     r6, r6, #(1 << 10)              @ clear it in "mmuset"
#endif
    # 首先mrc指令读取c1到r0.
    mrc    p15, 0, r0, c1, c0, 0        @ read control register
    # 然后清除clear(r5) - 0x0120c302常量指定的比特位
    bic    r0, r0, r5            @ clear bits them
    # 然后设置mmuset(r6) - 0x10c03c7d指定的比特位，其中bit23为1.
    # 表示为ARMv6以上特有的MMU页表描述符格式.
    orr    r0, r0, r6            @ set them
 THUMB(    orr    r0, r0, #1 << 30    )    @ Thumb exceptions
    # 在mov pc, lr跳转后将执行定义在head.S中的__enable_mmu函数，在进一步调节其它的比特位后
    # 最终将把r0中的值写回c1寄存器。
    mov    pc, lr                @ return to head.S:__ret
ENDPROC(__v7_setup)
```

### __enable_mmu

https://github.com/novelinux/linux-4.x.y/tree/master/arch/arm/kernel/head.S/README.md

CP15
----------------------------------------

https://github.com/leeminghao/doc-linux/blob/master/arch/arm/common/CP15.md
