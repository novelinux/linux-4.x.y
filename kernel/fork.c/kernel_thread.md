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

调用kernel_thread函数可启动一个内核线程:

path: kernel/fork.c
```
/*
 * Create a kernel thread.
 */
pid_t kernel_thread(int (*fn)(void *), void *arg, unsigned long flags)
{
    return _do_fork(flags|CLONE_VM|CLONE_UNTRACED, (unsigned long)fn,
           (unsigned long)arg, NULL, NULL, 0);
}
```

_do_fork
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/kernel/fork.c/_do_fork.md
