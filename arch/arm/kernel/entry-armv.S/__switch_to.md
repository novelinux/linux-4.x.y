__switch_to
========================================

switch_to的有趣之处在于，调度过程可能选择了一个新进程，而清理则是针对此前的活动进程。请注意，这不是发起上下文切换的那个进程，而是系统中随机的某个其他进程！内核必须想办法使得该进程能够与context_switch例程通信，这可以通过switch_to宏实现。每个体系结构都必须实现它，而且有一个异乎寻常的调用约定，即通过3个参数传递两个变量！这是因为上下文切换不仅涉及两个进程，而是3个进程。

**[Switch To](./switch_to.jpeg)**

假定3个进程A、B和C在系统上运行。在某个时间点，内核决定从进程A切换到进程B，然后从进程B到进程C，再接下来从进程C切换回进程A。在每个switch_to调用之前，next和prev指针位于各进程的栈上，prev指向当前运行的进程，而next指向将要运行的下一个进程。为执行从prev到next的切换，switch_to的前两个参数足够了。对进程A来说，prev指向进程A而next指向进程B。在进程A被选中再次执行时，会出现一个问题。控制权返回至switch_to之后的点，如果栈准确地恢复到切换之前的状态，那么prev和next仍然指向切换之前的值，即next = B而prev= A。在这种情况下，内核无法知道实际上在进程A之前运行的是进程C。因此，在新进程被选中时，底层的进程切换例程必须将此前执行的进程提供给context_switch。由于控制流会回到该函数的中间，这无法用普通的函数返回值来做到，因此使用了一个3个参数的宏。但逻辑上的效果是相同的，仿佛switch_to是带有两个参数的函数，而且返回了一个指向此前运行进程的指针。switch_to宏实际上执行的代码如下：

```
prev = switch_to(prev,next)
```

其中返回的prev值并不是用作参数的prev值，而是上一个执行的进程。在上述例子中，进程A提供给switch_to的参数是A和B，但恢复执行后得到的返回值是prev = C。内核实现该行为特性的方式依赖于底层的体系结构，但内核显然可以通过考虑两个进程的核心态栈来重建所要的信息。对可以访问所有内存的内核而言，这两个栈显然是同时可用的。

该函数的实质就是将移出进程的寄存器上下文保存到移出进程的thread_info->cpu_context结构体中。
并且将移入进程的thread_info->cpu_context结构体中的值restore到cpu的寄存器中，从而实现堆栈，
pc指针和cpu通用寄存器都切换到新的进程上开始执行。

Save Current Task Context
----------------------------------------

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
    add    ip, r1, #TI_CPU_SAVE
    @ 保存被切换出去的线程的寄存器到自己的线程栈中，保存在它自己的thread_info的cpu_context里
 ARM(    stmia    ip!, {r4 - sl, fp, sp, lr} )    @ Store most regs on stack
 THUMB(    stmia    ip!, {r4 - sl, fp}       )    @ Store most regs on stack
 THUMB(    str    sp, [ip], #4           )
 THUMB(    str    lr, [ip], #4           )
    @ r2是将要切换到运行的线程的thread_info, r4,r5中保存将要运行线程thread_info中的tp_value
    ldr    r4, [r2, #TI_TP_VALUE]
    ldr    r5, [r2, #TI_TP_VALUE + 4]
#ifdef CONFIG_CPU_USE_DOMAINS
    @ r6存着下一个线程的DOMAIN属性
    mrc    p15, 0, r6, c3, c0, 0        @ Get domain register
    str    r6, [r1, #TI_CPU_DOMAIN]    @ Save old domain register
    ldr    r6, [r2, #TI_CPU_DOMAIN]
#endif
```

### TI_CPU_SAVE vs TI_TP_VALUE

https://github.com/novelinux/linux-4.x.y/blob/master/arch/arm/kernel/asm-offsets.c/TI_XXX.md

switch_tls
----------------------------------------

```
    switch_tls r1, r4, r5, r3, r7
```

https://github.com/novelinux/linux-4.x.y/tree/master/arch/arm/include/asm/tls.h/switch_tls.md

__stack_chk_guard
-----------------------

```
#if defined(CONFIG_CC_STACKPROTECTOR) && !defined(CONFIG_SMP)
    @ 下一个线程的task_struct
    ldr    r7, [r2, #TI_TASK]
    @ r8里面是__stack_chk_guard地址
    ldr    r8, =__stack_chk_guard
    @ r7里面是stack_canary值
    ldr    r7, [r7, #TSK_STACK_CANARY]
#endif
#ifdef CONFIG_CPU_USE_DOMAINS
    @ 设置domain寄存器
    mcr    p15, 0, r6, c3, c0, 0        @ Set domain register
#endif
    @ r5里面是上一个线程的task_struct
    mov    r5, r0
    @ r4就是下一个线程的thread_info里面的cpu_context的地址
    add    r4, r2, #TI_CPU_SAVE
    ldr    r0, =thread_notify_head
    mov    r1, #THREAD_NOTIFY_SWITCH
    bl    atomic_notifier_call_chain
#if defined(CONFIG_CC_STACKPROTECTOR) && !defined(CONFIG_SMP)
    str    r7, [r8]
#endif
```

### TI_TASK

https://github.com/novelinux/linux-4.x.y/blob/master/arch/arm/kernel/asm-offsets.c/TI_XXX.md

Restore Next Task Context
----------------------------------------

```
 THUMB(    mov    ip, r4               )
    @ r0重新指向上一个线程的task_struct
    mov    r0, r5
 @ 这里就是恢复现场,pc对应了下个进程的cpu_context->pc从上面看到这个cpu_context->pc就是
 @ 之前保存现场的lr,就是下个线程要执行的地方。
 @ 注意：这里的pc值就是copy_thread中设置的ret_from_fork了.
 ARM(    ldmia    r4, {r4 - sl, fp, sp, pc}  )    @ Load all regs saved previously

 THUMB(    ldmia    ip!, {r4 - sl, fp}       )    @ Load all regs saved previously
 THUMB(    ldr    sp, [ip], #4           )
 THUMB(    ldr    pc, [ip]           )
 UNWIND(.fnend        )
ENDPROC(__switch_to)
```

**Notes:**

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

**注意**: __switch_to函数用户切换线程上下文，而vector_swi用来切换模式上下文.

https://github.com/novelinux/linux-4.x.y/tree/master/arch/arm/include/asm/thread_info.h/res/threadinfo.png

ret_from_fork
----------------------------------------

__switch_to最后一句将子进程thread_info中的cpu_context装载到CPU的寄存器里。这里的pc值就是
copy_thread()中设置的ret_from_fork了。

### copy_thread

https://github.com/novelinux/linux-4.x.y/tree/master/arch/arm/kernel/process.c/copy_thread.md

### ret_from_fork

接下来将要调用ret_from_fork继续后续工作:

https://github.com/novelinux/linux-4.x.y/tree/master/arch/arm/kernel/entry-common.S/ret_from_fork.md
