ret_fast_syscall
========================================

path: arch/arm/kernel/entry-common.S
```
/*
 * This is the fast syscall return path.  We do as little as
 * possible here, and this includes saving r0 back into the SVC
 * stack.
 */
ret_fast_syscall:
    ...
    disable_irq                @ disable interrupts
    ldr    r1, [tsk, #TI_FLAGS]
    tst    r1, #_TIF_WORK_MASK
    bne    fast_work_pending

    ...

    /* perform architecture specific actions before user return */
    arch_ret_to_user r1, lr

    restore_user_regs fast = 1, offset = S_OFF
```

restore_user_regs
----------------------------------------

restore_user_regs基本上是vector_swi的逆过程了。注意restore_user_regs最后一句代码，mov后面带s，
且目标寄存器是pc。这是一种特殊的用法，CPU会将当前spsr中的值写入cpsr中，这样就回到了用户态。
以上就是系统调用时的CPU寄存器的保护和还原过程。

https://github.com/novelinux/linux-4.x.y/tree/master/arch/arm/kernel/entry-header.S/restore_user_regs.md

系统调用刚进入到内核态，就会将当前的寄存器组保存在内核态的栈中；
当系统调用执行完内核态时，会将内核态栈中的寄存器组重新装载进来。
其他的模式切换也是相同的原理。
