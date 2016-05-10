ftrace
========================================

ftrace 是内建于Linux内核的跟踪工具，从 2.6.27 开始加入主流内核。使用 ftrace 可以调试
或者分析内核中发生的事情。ftrace 提供了不同的跟踪器，以用于不同的场合，比如跟踪内核
函数调用、对上下文切换进行跟踪、查看中断被关闭的时长、跟踪内核态中的延迟以及性能问题等。
系统开发人员可以使用 ftrace 对内核进行跟踪调试，以找到内核中出现的问题的根源，方便对其进行修复。
另外，对内核感兴趣的读者还可以通过 ftrace 来观察内核中发生的活动，了解内核的工作机制。

相关配置选项
----------------------------------------

```
CONFIG_FUNCTION_TRACER
CONFIG_FUNCTION_GRAPH_TRACER
CONFIG_NOP_TRACER
CONFIG_CONTEXT_SWITCH_TRACER
CONFIG_SCHED_TRACER
```

official
----------------------------------------

https://github.com/torvalds/linux/tree/bdec41963890f8ed9ad89f8b418959ab3cdc2aa3/Documentation/trace/ftrace.txt