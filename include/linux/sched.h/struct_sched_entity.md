## struct sched_entity

由于调度器可以操作比进程更一般的实体，因此需要一个适当的数据结构来描述此类实体。

### load

load指定了权重，决定了各个实体占队列总负荷的比例。计算负荷权重是调度器的一项重任，因为CFS所需的虚拟时钟的速度最终依赖于负荷

```
struct sched_entity {
	/* For load-balancing: */
	struct load_weight		load;
	unsigned long			runnable_weight;
```

### run_node

run_node是标准的树结点，使得实体可以在红黑树上排序。

```
	struct rb_node			run_node;
	struct list_head		group_node;
```

### on_rq

表示该实体当前是否在就绪队列上接受调度。

```
	unsigned int			on_rq;
```

### sum_exec_runtime

在进程运行时，我们需要记录消耗的CPU时间，以用于完全公平调度器。sum_exec_runtime即用于该目的。跟踪运行时间是由update_curr不断累积完成的。调度器中许多地方都会调用该函数，例如，新进程加入就绪队列时，或者周期性调度器中。每次调用时，会计算当前时间和exec_start之间的差值，exec_start则更新到当前时间。差值则被加到sum_exec_runtime。在进程执行期间虚拟时钟上流逝的时间数量由vruntime统计。


```
	u64				exec_start;
	u64				sum_exec_runtime;
	u64				vruntime;
```

### prev_sum_exec_runtime

在进程被撤销CPU时，其当前sum_exec_runtime值保存到prev_exec_runtime。此后，在进程抢占时又需要该数据。但请注意，在prev_exec_runtime中保存sum_exec_runtime的值，并不意味着重置sum_exec_run-time！原值保存下来，而sum_exec_runtime则持续单调增长。

```
	u64				prev_sum_exec_runtime;

	u64				nr_migrations;

	struct sched_statistics		statistics;

#ifdef CONFIG_FAIR_GROUP_SCHED
	int				depth;
	struct sched_entity		*parent;
	/* rq on which this entity is (to be) queued: */
	struct cfs_rq			*cfs_rq;
	/* rq "owned" by this entity/group: */
	struct cfs_rq			*my_q;
#endif

#ifdef CONFIG_SMP
	/*
	 * Per entity load average tracking.
	 *
	 * Put into separate cache line so it does not
	 * collide with read-mostly values above.
	 */
	struct sched_avg		avg;
#endif
};
```