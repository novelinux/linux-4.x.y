__switch_to
========================================

__switch_to函数是由函数switch_to来调用的:

https://github.com/novelinux/linux-4.x.y/tree/master/arch/arm/include/asm/switch_to.h/switch_to.md

path: arch/arm/kernel/asm-offsets.c
```
  ...
#ifdef CONFIG_CC_STACKPROTECTOR
  DEFINE(TSK_STACK_CANARY,    offsetof(struct task_struct, stack_canary));
#endif
  ...
  DEFINE(TI_TASK,        offsetof(struct thread_info, task));
  ...
  DEFINE(TI_CPU_DOMAIN,  offsetof(struct thread_info, cpu_domain));
  DEFINE(TI_CPU_SAVE,    offsetof(struct thread_info, cpu_context));
  ...
  DEFINE(TI_TP_VALUE,    offsetof(struct thread_info, tp_value));
```

path: arch/arm/kernel/entry-armv.S
```
/*
 * Register switch for ARMv3 and ARMv4 processors
 * r0 = previous task_struct, r1 = previous thread_info, r2 = next thread_info
 * previous and next are guaranteed not to be the same.
 */
ENTRY(__switch_to)
 UNWIND(.fnstart    )
 UNWIND(.cantunwind    )
    @ r1是被切换出去的线程的thread_info, ip(r12)寄存器中保存切换出去线程的cpu上下文
    add  ip, r1, #TI_CPU_SAVE
    @ r2是将要切换到运行的线程的thread_info, r3中保存将要运行线程thread_info中的tp_value
    ldr  r3, [r2, #TI_TP_VALUE]
    @ 保存被切换出去的线程的寄存器到自己的线程栈中，保存在它自己的thread_info的cpu_context里
 ARM(    stmia    ip!, {r4 - sl, fp, sp, lr} )    @ Store most regs on stack

 THUMB(  stmia    ip!, {r4 - sl, fp}       )    @ Store most regs on stack
 THUMB(  str    sp, [ip], #4           )
 THUMB(  str    lr, [ip], #4           )
#ifdef CONFIG_CPU_USE_DOMAINS
    @ r6存着下一个线程的DOMAIN属性
    ldr  r6, [r2, #TI_CPU_DOMAIN]
#endif
    set_tls    r3, r4, r5
#if defined(CONFIG_CC_STACKPROTECTOR) && !defined(CONFIG_SMP)
    @ 下一个线程的task_struct
    ldr  r7, [r2, #TI_TASK]
    @ r8里面是__stack_chk_guard地址
    ldr  r8, =__stack_chk_guard
    @ r7里面是stack_canary值
    ldr  r7, [r7, #TSK_STACK_CANARY]
#endif
#ifdef CONFIG_CPU_USE_DOMAINS
#ifdef CONFIG_EMULATE_DOMAIN_MANAGER_V7
    stmdb r13!, {r0-r3, lr}
    mov   r0, r6
    bl    emulate_domain_manager_set
    ldmia r13!, {r0-r3, lr}
#else
    @ 设置domain寄存器
    mcr   p15, 0, r6, c3, c0, 0        @ Set domain register
#endif
#endif
    @ r5里面是上一个线程的task_struct
    mov   r5, r0
    @ r4就是下一个线程的thread_info里面的cpu_context的地址
    add   r4, r2, #TI_CPU_SAVE

    ldr   r0, =thread_notify_head
    mov   r1, #THREAD_NOTIFY_SWITCH
    bl    atomic_notifier_call_chain
#if defined(CONFIG_CC_STACKPROTECTOR) && !defined(CONFIG_SMP)
    str   r7, [r8]
#endif
 THUMB(   mov    ip, r4               )
    @ r0重新指向上一个线程的task_struct
    mov   r0, r5

 @ 这里就是恢复现场,pc对应了下个进程的cpu_context->pc从上面看到这个cpu_context->pc就是
 @ 之前保存现场的lr,就是下个线程要执行的地方。
 @ 注意：这里的pc值就是copy_thread中设置的ret_from_fork了.
 ARM(    ldmia    r4, {r4 - sl, fp, sp, pc}  )    @ Load all regs saved previously

 THUMB(  ldmia    ip!, {r4 - sl, fp}       )    @ Load all regs saved previously
 THUMB(  ldr    sp, [ip], #4           )
 THUMB(  ldr    pc, [ip]           )
 UNWIND(.fnend        )
ENDPROC(__switch_to)
```

该函数的实质就是将移出进程的寄存器上下文保存到移出进程的thread_info->cpu_context结构体中。
并且将移入进程的thread_info->cpu_context结构体中的值restore到cpu的寄存器中，从而实现堆栈，
pc指针和cpu通用寄存器都切换到新的进程上开始执行。

https://github.com/novelinux/linux-4.x.y/tree/master/arch/arm/include/asm/thread_info.h/thread_info.md

set_tls
----------------------------------------

tp_value就是为了设置TLS register的值,在多线程应用程序，其中一个进程共享相同的地址空间中的
所有线程，还有经常出现需要维护的数据是唯一的一个线程。TLS或线程本地存储，是用于线程抽象的概念。
它是一种快速和有效的方式来存储每个线程的本地数据。线程的本地数据的偏移量是通过TLS寄存器
(H/W或S/W块)，它指向线程各自的线程控制块访问。之前ARM内核，甚至ARM9和ARM11核心的一些不具备
这种TLS注册物理上可用。操作系统（Linux从这里开始）需要效仿的软件。新一代的ARM内核。Cortex-AX起，
确实有这TLS的寄存器可用（CP15）。内核对TLS需要做的事情是能够让用户态程序
（通常是nptl——一个pthread的实现）在某个时刻能够设置线程唯一的基址值到内核的线程信息结构内。

https://github.com/novelinux/linux-4.x.y/tree/master/arch/arm/include/asm/tls.h/set_tls.md

ret_from_fork
----------------------------------------

__switch_to最后一句将子进程thread_info中的cpu_context装载到CPU的寄存器里。这里的pc值就是
copy_thread()中设置的ret_from_fork了。

copy_thread:

https://github.com/novelinux/linux-4.x.y/tree/master/arch/arm/kernel/process.c/copy_thread.md

接下来将要调用ret_from_fork继续后续工作:

https://github.com/novelinux/linux-4.x.y/tree/master/arch/arm/kernel/entry-common.S/ret_from_fork.md

注意
----------------------------------------

由于switch_to是一个函数，所以对他的寄存器的保存，同样也遵循arm的APCS标准，但又跟APCS又不完全一样。

* 跟APCS不一样的地方表现在：

保存移出进程的寄存器上下时，保存了lr的地址，而并未保存pc值，而此时的lr寄存器的地址即为
context_switch函数中的switch_to的下一行，即barrier()函数的开始地址。

* 跟APCS相同的地方表现在:

r0-r3都未保存，因为根据APCS约束，这4个寄存器都是用来存函数的参数，可以不入栈保存。
r4-r10，根据APCS约束，由于这些寄存器会被编译器用来暂存变量的值，因为会被修改，需要
入栈保存和出栈恢复。

我们知道在中断处理过程中，linux arm是有将cpsr寄存器也做了保存，而为什么在上下文切换时，
却不需要保存呢？

因为中断发生是随机不确定的，他可能在任何指令的后面产生中断，而cpsr只会影响到中断指令的下面的
指令的执行，如果被中断时的指令的下一条指令的执行是依赖于cpsr的，如果中断处理程序修改了cpsr值，
而又没保存，会导致中断返回时，在执行下条指令时，会出现逻辑错误。

而上下文切换的返回地址和接下来要执行的指令是确定的，只要上下文切换回来的指令不受cpsr值得影响
(不依赖cpsr)，则就可以不保存cpsr寄存器的值.

**注意**: __switch_to函数用户切换线程上下文，而ret_from_fork用来切换模式上下文.

https://github.com/novelinux/linux-4.x.y/tree/master/arch/arm/include/asm/thread_info.h/res/threadinfo.png