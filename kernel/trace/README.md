TRACE
========================================

* Function tracer和Function graph tracer: 跟踪函数调用。
* Schedule switch tracer: 跟踪进程调度情况。
* Wakeup tracer: 跟踪进程的调度延迟，即高优先级进程从进入ready状态到获得CPU的延迟时间。该tracer只针对实时进程。
* Irqsoff tracer: 当中断被禁止时，系统无法相应外部事件，比如键盘和鼠标，时钟也无法产生tick中断。
    这意味着系统响应延迟，irqsoff这个tracer能够跟踪并记录内核中哪些函数禁止了中断,
    对于其中中断禁止时间最长的，irqsoff 将在 log 文件的第一行标示出来, 从而使开发人员可以迅速定位造成响应延迟的罪魁祸首。
* Preemptoff tracer: 和前一个 tracer 类似，preemptoff tracer 跟踪并记录禁止内核抢占的函数，
    并清晰地显示出禁止抢占时间最长的内核函数。
* Preemptirqsoff tracer: 同上，跟踪和记录禁止中断或者禁止抢占的内核函数，以及禁止时间最长的函数。
* Branch tracer: 跟踪内核程序中的 likely/unlikely分支预测命中率情况。
    Branch tracer 能够记录这些分支语句有多少次预测成功。从而为优化程序提供线索。
* Hardware branch tracer: 利用处理器的分支跟踪能力，实现硬件级别的指令跳转记录。在x86上，主要利用了BTS这个特性。
* Initcall tracer: 记录系统在 boot 阶段所调用的 init call 。
* Mmiotrace tracer: 记录memory map IO的相关信息。
* Power tracer: 记录系统电源管理相关的信息。
* Sysprof tracer: 缺省情况下，sysprof tracer 每隔1 msec对内核进行一次采样，记录函数调用和堆栈信息。
* Kernel memory tracer: 内存tracer主要用来跟踪 slab allocator 的分配情况。
    包括kfree，kmem_cache_alloc等API 的调用情况，用户程序可以根据tracer收集到的信息分析内部碎片情况，
    找出内存分配最频繁的代码片断，等等。
* Workqueue statistical tracer: 这是一个 statistic tracer，统计系统中所有的workqueue的工作情况，
    比如有多少个work被插入workqueue，多少个已经被执行等。开发人员
    可以以此来决定具体的 workqueue 实现，比如是使用single threaded workqueue 还是per cpu workqueue.
* Event tracer: 跟踪系统事件，比如 timer，系统调用，中断等。

ftrace
----------------------------------------

https://github.com/leeminghao/doc-linux/tree/master/4.x.y/kernel/trace/ftrace/README.md
