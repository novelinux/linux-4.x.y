kernel_thread_helper
========================================

path: arch/arm/kernel/process.c
```
/*
 * Shuffle the argument into the correct register before calling the
 * thread function.  r4 is the thread argument, r5 is the pointer to
 * the thread function, and r6 points to the exit function.
 */
extern void kernel_thread_helper(void);
asm(    ".pushsection .text\n"
"    .align\n"
"    .type    kernel_thread_helper, #function\n"
"kernel_thread_helper:\n"
#ifdef CONFIG_TRACE_IRQFLAGS
"    bl    trace_hardirqs_on\n"
#endif
"    msr    cpsr_c, r7\n"
@ r0寄存器保存了传递给子线程(内核线程)入口函数的参数
"    mov    r0, r4\n"
@ r6保存了子线程调用返回后调用的kernel_thread_exit函数来回收对应资源.
"    mov    lr, r6\n"
@ 将子线程入口函数传递给pc寄存器，最终跳转到入口函数执行
"    mov    pc, r5\n"
"    .size    kernel_thread_helper, . - kernel_thread_helper\n"
"    .popsection");

#ifdef CONFIG_ARM_UNWIND
extern void kernel_thread_exit(long code);
asm(    ".pushsection .text\n"
"    .align\n"
"    .type    kernel_thread_exit, #function\n"
"kernel_thread_exit:\n"
"    .fnstart\n"
"    .cantunwind\n"
"    bl    do_exit\n"
"    nop\n"
"    .fnend\n"
"    .size    kernel_thread_exit, . - kernel_thread_exit\n"
"    .popsection");
#else
#define kernel_thread_exit    do_exit
#endif
```