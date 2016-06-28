ret_from_fork
========================================

path: arch/arm/kernel/entry-common.S
```
/*
 * This is how we return from a fork.
 */
ENTRY(ret_from_fork)
	bl	schedule_tail
	cmp	r5, #0
	movne	r0, r4
	badrne	lr, 1f
	retne	r5
1:	get_thread_info tsk
	b	ret_slow_syscall
ENDPROC(ret_from_fork)
```

ret_slow_syscall
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/arch/arm/kernel/entry-common.S/ret_slow_syscall.md

注意: 我们在__switch_to函数中已经恢复过一次当前线程的上下文了(struct cpu_context_save),
接下来又调用ret_slow_syscall->restore_user_regs来恢复模式上下文(struct pt_regs).