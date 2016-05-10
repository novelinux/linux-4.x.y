context_switch
========================================

内核选择新进程之后，必须处理与多任务相关的技术细节.这些细节总称为上下文切换（context switching）。
辅助函数context_switch是个分配器，它会调用所需的特定于体系结构的方法。

1.prepare_task_switch
----------------------------------------

紧接着进程切换之前，prepare_task_switch会调用每个体系结构都必须定义的prepare_arch_switch挂钩。
这使得内核执行特定于体系结构的代码，为切换做事先准备。大多数支持的体系结构（Sparc64和Sparc除外）
都不需要该选项，因此并未使用。

```
/*
 * context_switch - switch to the new MM and the new
 * thread's register state.
 */
static inline void
context_switch(struct rq *rq, struct task_struct *prev,
           struct task_struct *next)
{
    struct mm_struct *mm, *oldmm;

    prepare_task_switch(rq, prev, next);
```

2.上下文切换
----------------------------------------

上下文切换本身通过调用两个特定于处理器的函数完成:

* 1.switch_mm更换通过task_struct->mm描述的内存管理上下文。该工作的细节取决于处理器，
  主要包括加载页表、刷出地址转换后备缓冲器（部分或全部）、向内存管理单元（MMU）提供新的信息。
* 2.switch_to切换处理器寄存器内容和内核栈（虚拟地址空间的用户部分在第一步已经变更，其中也包括了
  用户状态下的栈，因此用户栈就不需要显式变更了）。此项工作在不同的体系结构下可能差别很大，代码
  通常都使用汇编语言编写。

```
    mm = next->mm;
    oldmm = prev->active_mm;

    /*
     * For paravirt, this is coupled with an exit in switch_to to
     * combine the page table reload and the switch backend into
     * one hypercall.
     */
    arch_start_context_switch(prev);

    // 内核线程没有自身的用户空间内存上下文，可能在某个随机进程地址空间的上部执行。
    // 其task_struct->mm为NULL。从当前进程“借来”的地址空间记录在active_mm中：
    if (!mm) {
        next->active_mm = oldmm;
        atomic_inc(&oldmm->mm_count);
        // enter_lazy_tlb通知底层体系结构不需要切换虚拟地址空间的用户空间部分。
        // 这种加速上下文切换的技术称之为惰性TLB。
        enter_lazy_tlb(oldmm, next);
    } else
        switch_mm(oldmm, mm, next);

    // 如果前一进程是内核线程（即prev->mm为NULL），则其active_mm指针必须重置为NULL，
    // 以断开与借用的地址空间的联系：
    if (!prev->mm) {
        prev->active_mm = NULL;
        rq->prev_mm = oldmm;
    }
    /*
     * Since the runqueue lock will be released by the next
     * task (which is an invalid locking op but in the case
     * of the scheduler it's an obvious special-case), so we
     * do an early lockdep release here:
     */
#ifndef __ARCH_WANT_UNLOCKED_CTXSW
    spin_release(&rq->lock.dep_map, 1, _THIS_IP_);
#endif

    /* Here we just switch the register state and the stack. */
    // 最后用switch_to完成进程切换，该函数切换寄存器状态和栈，新进程在该调用之后开始执行
    switch_to(prev, next, prev);

    // switch_to之后的代码只有在当前进程下一次被选择运行时才会执行。finish_task_switch完成
    // 一些清理工作，使得能够正确地释放锁。它也向各个体系结构提供了另一个挂钩上下文切换过程
    // 的可能性，但只在少量计算机上需要。barrier语句是一个编译器指令，确保switch_to和
    // finish_task_switch语句的执行顺序不会因为任何可能的优化而改变.
    barrier();
    /*
     * this_rq must be evaluated again because prev may have moved
     * CPUs since it called schedule(), thus the 'rq' on its stack
     * frame will be invalid.
     */
    finish_task_switch(this_rq(), prev);
}
```

switch_to
----------------------------------------

### arm

https://github.com/novelinux/linux-4.x.y/tree/master/arch/arm/include/asm/switch_to.h/switch_to.md
