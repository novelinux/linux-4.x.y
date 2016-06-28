restore_user_regs
========================================

restore_user_regs是vector_swi的逆过程.

path: arch/arm/kernel/entry-header.S
```
    .macro    restore_user_regs, fast = 0, offset = 0
    ldr    r1, [sp, #\offset + S_PSR]    @ get calling cpsr
    @ 获取sp_svc中保存的PC指针,也就是系统调用用户态返回地址.
    @ 注意:如果是内核线程，该值为kernel_thread_helper函数地址.
    ldr    lr, [sp, #\offset + S_PC]!    @ get pc
    msr    spsr_cxsf, r1            @ save in spsr_svc
#if defined(CONFIG_CPU_V6)
    strex    r1, r2, [sp]            @ clear the exclusive monitor
#elif defined(CONFIG_CPU_32v6K)
    clrex                    @ clear the exclusive monitor
#endif
    .if    \fast
    @ 这里的^标志表示将pt_regs中保存的模式上下文恢复到用户态模式.
    ldmdb    sp, {r1 - lr}^            @ get calling r1 - lr
    .else
    ldmdb    sp, {r0 - lr}^            @ get calling r0 - lr
    .endif
    mov    r0, r0                @ ARMv5T and earlier require a nop
                        @ after ldm {}^
    add    sp, sp, #S_FRAME_SIZE - S_PC
    movs    pc, lr                @ return & move spsr_svc into cpsr
    .endm

    .macro    get_thread_info, rd
    mov    \rd, sp, lsr #13
    mov    \rd, \rd, lsl #13
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