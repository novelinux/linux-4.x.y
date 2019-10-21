## scheduler_tick

该函数有下面两个主要任务。

*（1）管理内核中与整个系统和各个进程的调度相关的统计量。其间执行的主要操作是对各种计数器加1.
*（2）激活负责当前进程的调度类的周期性调度方法。

该函数的第一部分处理就绪队列时钟的更新。该职责委托给update_rq_clock完成，本质上就是增加struct rq当前实例的时钟时间戳。该函数必须处理硬件时钟的一些奇异之处。由于调度器的模块化结构，主体工程实际上比较简单，因为主要的工作可以完全委托给特定调度器类的方法：

task_tick的实现方式取决于底层的调度器类。例如，完全公平调度器会在该方法中检测是否进程已经运行太长时间，以避免过长的延迟。如果熟悉旧的基于时间片的调度方法，那么应该会知道，这里的做法实际上不等价于到期的时间片，因为完全公平调度器中不再存在所谓时间片的概念。如果当前进程应该被重新调度，那么调度器类方法会在task_struct中设置TIF_NEED_RESCHED标志，以表示该请求，而内核会在接下来的适当时机完成该请求。

```
/*
 * This function gets called by the timer code, with HZ frequency.
 * We call it with interrupts disabled.
 */
void scheduler_tick(void)
{
	int cpu = smp_processor_id();
	struct rq *rq = cpu_rq(cpu);
	struct task_struct *curr = rq->curr;
	struct rq_flags rf;

	sched_clock_tick();

	rq_lock(rq, &rf);

	update_rq_clock(rq);
	curr->sched_class->task_tick(rq, curr, 0);
	cpu_load_update_active(rq);
	calc_global_load_tick(rq);
	psi_task_tick(rq);

	rq_unlock(rq, &rf);

	perf_event_task_tick();

#ifdef CONFIG_SMP
	rq->idle_balance = idle_cpu(cpu);
	trigger_load_balance(rq);
#endif
}
```