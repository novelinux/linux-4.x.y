INIT_THREAD_INFO
========================================

path: arch/arm/include/asm/thread_info.h
```
#define INIT_THREAD_INFO(tsk)						\
{									\
	.task		= &tsk,						\
	.flags		= 0,						\
	.preempt_count	= INIT_PREEMPT_COUNT,				\
	.addr_limit	= KERNEL_DS,					\
}
```