ret_from_fork
========================================

path: arch/arm/kernel/entry-common.S
```
/*
 * This is how we return from a fork.
 */
ENTRY(ret_from_fork)
    bl    schedule_tail
    get_thread_info tsk
    ldr    r1, [tsk, #TI_FLAGS]        @ check for syscall tracing
    mov    why, #1
    tst    r1, #_TIF_SYSCALL_WORK        @ are we tracing syscalls?
    beq    ret_slow_syscall
    mov    r1, sp
    mov    r0, #1                @ trace exit [IP = 1]
    bl    syscall_trace
    b    ret_slow_syscall
ENDPROC(ret_from_fork)
```

ret_slow_syscall
----------------------------------------

path: arch/arm/kernel/entry-common.S
```
/*
 * "slow" syscall return path.  "why" tells us if this was a real syscall.
 */
ENTRY(ret_to_user)
ret_slow_syscall:
    disable_irq                @ disable interrupts
ENTRY(ret_to_user_from_irq)
    ldr    r1, [tsk, #TI_FLAGS]
    tst    r1, #_TIF_WORK_MASK
    bne    work_pending
no_work_pending:
#if defined(CONFIG_IRQSOFF_TRACER)
    asm_trace_hardirqs_on
#endif
    /* perform architecture specific actions before user return */
    arch_ret_to_user r1, lr

    restore_user_regs fast = 0, offset = 0
ENDPROC(ret_to_user_from_irq)
ENDPROC(ret_to_user)
```

ret_slow_syscall和ret_fast_syscall差不多，都在调用restore_user_regs，不一样的是参数fast。

ret_fast_syscall详见:

https://github.com/leeminghao/doc-linux/blob/master/4.x.y/arch/arm/kernel/entry-common.S/vector_swi.md

注意: 我们在__switch_to函数中已经恢复过一次当前线程的上下文了(struct cpu_context_save),
接下来又调用restore_user_regs来恢复模式上下文(struct pt_regs).

https://github.com/leeminghao/doc-linux/blob/master/4.x.y/arch/arm/include/asm/thread_info.h/res/threadinfo.png

restore_user_regs
----------------------------------------

https://github.com/leeminghao/doc-linux/blob/master/4.x.y/arch/arm/kernel/entry-header.S/restore_user_regs.md
