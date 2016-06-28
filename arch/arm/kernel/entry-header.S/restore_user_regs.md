restore_user_regs
========================================

restore_user_regs是vector_swi的逆过程.

path: arch/arm/kernel/entry-header.S
```
	.macro	restore_user_regs, fast = 0, offset = 0
	uaccess_enable r1, isb=0
#ifndef CONFIG_THUMB2_KERNEL
	@ ARM mode restore
	mov	r2, sp
       @ 获取sp_svc中保存的PC指针,也就是系统调用用户态返回地址.
       @ 注意:如果是内核线程，该值为kernel_thread_helper函数地址.
	ldr	r1, [r2, #\offset + S_PSR]	@ get calling cpsr
	ldr	lr, [r2, #\offset + S_PC]!	@ get pc
	msr	spsr_cxsf, r1			@ save in spsr_svc
#if defined(CONFIG_CPU_V6) || defined(CONFIG_CPU_32v6K)
	@ We must avoid clrex due to Cortex-A15 erratum #830321
	strex	r1, r2, [r2]			@ clear the exclusive monitor
#endif
	.if	\fast
        @ 这里的^标志表示将pt_regs中保存的模式上下文恢复到用户态模式.
	ldmdb	r2, {r1 - lr}^			@ get calling r1 - lr
	.else
	ldmdb	r2, {r0 - lr}^			@ get calling r0 - lr
	.endif
	mov	r0, r0				@ ARMv5T and earlier require a nop
						@ after ldm {}^
	add	sp, sp, #\offset + S_FRAME_SIZE
	movs	pc, lr				@ return & move spsr_svc into cpsr
#elif defined(CONFIG_CPU_V7M)
	@ V7M restore.
	@ Note that we don't need to do clrex here as clearing the local
	@ monitor is part of the exception entry and exit sequence.
	.if	\offset
	add	sp, #\offset
	.endif
	v7m_exception_slow_exit ret_r0 = \fast
#else
	@ Thumb mode restore
	mov	r2, sp
	load_user_sp_lr r2, r3, \offset + S_SP	@ calling sp, lr
	ldr	r1, [sp, #\offset + S_PSR]	@ get calling cpsr
	ldr	lr, [sp, #\offset + S_PC]	@ get pc
	add	sp, sp, #\offset + S_SP
	msr	spsr_cxsf, r1			@ save in spsr_svc

	@ We must avoid clrex due to Cortex-A15 erratum #830321
	strex	r1, r2, [sp]			@ clear the exclusive monitor

	.if	\fast
	ldmdb	sp, {r1 - r12}			@ get calling r1 - r12
	.else
	ldmdb	sp, {r0 - r12}			@ get calling r0 - r12
	.endif
	add	sp, sp, #S_FRAME_SIZE - S_SP
	movs	pc, lr				@ return & move spsr_svc into cpsr
#endif	/* !CONFIG_THUMB2_KERNEL */
	.endm
```

ret_slow_syscall和ret_fast_syscall差不多，都在调用restore_user_regs，不一样的是参数fast。
两者有什么区别呢？

当父进程调用fork()创建子进程后：
父进程会从ret_fast_syscall这个函数返回到用户态,详见vector_swi.

https://github.com/novelinux/linux-4.x.y/tree/master/arch/arm/kernel/entry-common.S/vector_swi.md

而子进程则是调用ret_from_fork，再调用ret_slow_syscall来返回到用户态:

https://github.com/novelinux/linux-4.x.y/tree/master/arch/arm/kernel/entry-common.S/ret_from_fork.md

两者的区别就是参数fast，而参数fast只是控制要不要把内核栈中保存的r0值写入到CPU r0寄存器里。

* 当fast = 1时，保持当前流程中的r0值，这个r0值是父进程的do_fork()返回值，也就是子进程的pid。
* 而fast = 0时，会用栈中的r0值替换当前的r0值，我们知道copy_thread()中，这个栈中的r0值被设置为0，
  所以子进程返回值将会是0。