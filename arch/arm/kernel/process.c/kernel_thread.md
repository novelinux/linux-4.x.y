kernel_thread
========================================

内核线程是直接由内核本身启动的进程。内核线程实际上是将内核函数委托给独立的进程，与系统中其
他进程“并行”执行（实际上，也并行于内核自身的执行）。内核线程经常称之为（内核）守护进程。
它们用于执行下列任务:

* 周期性地将修改的内存页与页来源块设备同步（例如，使用mmap的文件映射）。
* 如果内存页很少使用，则写入交换区。
* 管理延时动作（deferred action）。
* 实现文件系统的事务日志。

基本上，有两种类型的内核线程:

* 类型1：线程启动后一直等待，直至内核请求线程执行某一特定操作。
* 类型2：线程启动后按周期性间隔运行，检测特定资源的使用，在用量超出或低于预置的限制值时采取行动。
  内核使用这类线程用于连续监测任务。

流程
----------------------------------------

调用kernel_thread函数可启动一个内核线程。其定义是特定于体系结构的.

path: arch/arm/kernel/process.c
```
/*
 * Create a kernel thread.
 */
pid_t kernel_thread(int (*fn)(void *), void *arg, unsigned long flags)
{
    struct pt_regs regs;

    memset(&regs, 0, sizeof(regs));

    regs.ARM_r4 = (unsigned long)arg;
    regs.ARM_r5 = (unsigned long)fn;
    regs.ARM_r6 = (unsigned long)kernel_thread_exit;
    regs.ARM_r7 = SVC_MODE | PSR_ENDSTATE | PSR_ISETSTATE;
    regs.ARM_pc = (unsigned long)kernel_thread_helper;
    regs.ARM_cpsr = regs.ARM_r7 | PSR_I_BIT;

    return do_fork(flags|CLONE_VM|CLONE_UNTRACED, 0, &regs, 0, NULL, NULL);
}
EXPORT_SYMBOL(kernel_thread);
```

### 参数

* 产生的线程将执行用fn指针传递的函数;
* arg指定的参数将自动传递给该函数;
* flags中可指定CLONE标志。

### 流程

1.kernel_thread的第一个任务是构建一个pt_regs实例，对其中的寄存器指定适当的值.

注意: 在系统刚启动时sp是在__mmap_switched函数中指定的:

https://github.com/novelinux/linux-4.x.y/tree/master/arch/arm/kernel/head-common.S/__mmap_switched.md

2.接下来调用我们熟悉的do_fork函数。

https://github.com/novelinux/linux-4.x.y/tree/master/kernel/fork.c/do_fork.md

因为内核线程是由内核自身生成的，应该注意下面两个特别之处。

* 1.它们在CPU的管态(supervisor mode)执行，而不是用户状态;
* 2.它们只可以访问虚拟地址空间的内核部分（高于TASK_SIZE的所有地址），但不能访问用户空间。

3.当通过do_fork创建一个内核线程之后，通过调度函数__switch_to来恢复新创建的线程的线程上下文
之后，接下来调用ret_from_fork恢复了模式上下文(struct pt_regs). 也就是跳转到regs.ARM_pc所保存
的pc寄存器中的函数指针kernel_thread_helper中去执行.

https://github.com/novelinux/linux-4.x.y/tree/master/arch/arm/kernel/process.c/kernel_thread_helper.md

在kernel_thread_helper函数中最后会调用到对应子线程的入口函数去执行.
