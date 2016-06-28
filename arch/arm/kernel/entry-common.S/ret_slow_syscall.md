ret_slow_syscall
========================================

path: arch/arm/kernel/entry-common.S
```
/*
 * "slow" syscall return path.  "why" tells us if this was a real syscall.
 * IRQs may be enabled here, so always disable them.  Note that we use the
 * "notrace" version to avoid calling into the tracing code unnecessarily.
 * do_work_pending() will update this state if necessary.
 */
ENTRY(ret_to_user)
ret_slow_syscall:
    disable_irq_notrace            @ disable interrupts
ENTRY(ret_to_user_from_irq)
    ldr    r1, [tsk, #TI_FLAGS]
    tst    r1, #_TIF_WORK_MASK
    bne    slow_work_pending
no_work_pending:
    asm_trace_hardirqs_on save = 0

    /* perform architecture specific actions before user return */
    arch_ret_to_user r1, lr
    ct_user_enter save = 0

    restore_user_regs fast = 0, offset = 0
ENDPROC(ret_to_user_from_irq)
ENDPROC(ret_to_user)
```

restore_user_regs
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/arch/arm/kernel/entry-header.S/restore_user_regs.md

ret_slow_syscall和ret_fast_syscall差不多，都在调用restore_user_regs，不一样的是参数fast。
