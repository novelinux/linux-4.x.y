# workqueue

Workqueue 是内核里面很重要的一个机制，特别是内核驱动，一般的小型任务 (work) 都不会自己起一个线程来
处理，而是扔到 Workqueue 中处理。Workqueue 的主要工作就是用进程上下文来处理内核中大量的小任务。

所以 Workqueue 的主要设计思想：一个是并行，多个 work 不要相互阻塞；另外一个是节省资源，多个 work
尽量共享资源 ( 进程、调度、内存 )，不要造成系统过多的资源浪费。

为了实现的设计思想，workqueue 的设计实现也更新了很多版本。最新的 workqueue 实现叫做 CMWQ
(Concurrency Managed Workqueue)，也就是用更加智能的算法来实现“并行和节省”。新版本的 workqueue
创建函数改成 alloc_workqueue()，旧版本的函数 create_workqueue() 逐渐会被被废弃。

## CMWQ 的几个基本概念

关于 workqueue 中几个概念都是 work 相关的数据结构非常容易混淆，大概可以这样来理解：

* work: 工作。
* workqueue: 工作的集合。workqueue 和 work 是一对多的关系。
* worker: 工人, 在代码中 worker 对应一个 worker_thread() 内核线程。
* worker_pool: 工人的集合,worker_pool 和 worker 是一对多的关系。
* pool_workqueue(pwq): 中间人/中介，负责建立起workqueue和worker_pool之间的关系。

**NOTE**: workqueue和pwq是一对多的关系， pwq和worker_pool是一对一的关系

https://github.com/novelinux/linux-4.x.y/tree/master/kernel/workqueue.c/res/wq_topology.png

最终的目的还是把 work( 工作 ) 传递给 worker( 工人 ) 去执行，中间的数据结构和各种关系目的是把
这件事组织的更加清晰高效。

所以这其中有几个重点：

worker 怎么处理 work；
worker_pool 怎么动态管理 worker 的数量；

## worker_pool

每个执行 work 的线程叫做 worker，一组 worker 的集合叫做 worker_pool。CMWQ 的精髓就在
worker_pool里面worker 的动态增减管理上 manage_workers():

https://github.com/novelinux/system_calls/blob/master/fs/ext4-write.md

CMWQ 对 worker_pool 分成两类：

* normal worker_pool: 给通用的 workqueue 使用；
* unbound worker_pool: 给 WQ_UNBOUND 类型的的 workqueue 使；

### struct worker_pool

https://github.com/novelinux/linux-4.x.y/tree/master/kernel/workqueue.c/worker_pool.md

### normal worker_pool

默认 work 是在 normal worker_pool 中处理的。系统的规划是每个 CPU 创建两个 normal worker_pool：
一个 normal 优先级 (nice=0)、一个高优先级 (nice=HIGHPRI_NICE_LEVEL)，对应创建出来的 worker的进程
nice 不一样。

每个 worker 对应一个 worker_thread() 内核线程，一个 worker_pool 包含一个或者多个 worker，
worker_pool 中 worker 的数量是根据 worker_pool 中 work 的负载来动态增减的。

我们可以通过 ps | grep kworker 命令来查看所有 worker 对应的内核线程，normal worker_pool 对应
内核线程 (worker_thread()) 的命名规则是这样的：

path: kernel/workqueue.c
```
	if (pool->cpu >= 0) // normal worker_pool
		snprintf(id_buf, sizeof(id_buf), "%d:%d%s", pool->cpu, id,
			 pool->attrs->nice < 0  ? "H" : "");
	else // unbound worker_pool
		snprintf(id_buf, sizeof(id_buf), "u%d:%d", pool->id, id);
	worker->task = kthread_create_on_node(worker_thread, worker, pool->node,
					      "kworker/%s", id_buf);
```

类似名字是 normal worker_pool：

```
sagit:/ $ ps  | grep kworker
root      5     2     0      0              0 0000000000 S kworker/0:0H
root      17    2     0      0              0 0000000000 S kworker/1:0H
root      24    2     0      0              0 0000000000 S kworker/2:0H
root      31    2     0      0              0 0000000000 S kworker/3:0H
root      38    2     0      0              0 0000000000 S kworker/4:0H
root      45    2     0      0              0 0000000000 S kworker/5:0H
root      52    2     0      0              0 0000000000 S kworker/6:0H
root      59    2     0      0              0 0000000000 S kworker/7:0H
```

https://github.com/novelinux/linux-4.x.y/tree/master/kernel/workqueue.c/res/wq_normal_wq.png

对应的拓扑图如下：

https://github.com/novelinux/linux-4.x.y/tree/master/kernel/workqueue.c/res/wq_normal_wq_topology.png

normal worker_pool 详细的创建过程代码分析：

```
/* the per-cpu worker pools */
static DEFINE_PER_CPU_SHARED_ALIGNED(struct worker_pool [NR_STD_WORKER_POOLS], cpu_worker_pools);
 .
 .
workqueue_init_early
 |
for_each_possible_cpu
 |
for_each_cpu_worker_pool ( cpu_worker_pools )
 |
 +-> init_worker_pool
 |
 +-> worker_pool_assign_id
 .
 .
workqueue_init
 |
for_each_possible_cpu
 |
for_each_cpu_worker_pool (cpu_worker_pools)
 |
create_worker
 |
 +-> worker = alloc_worker
 |
 +-> worker->task = kthread_create_on_node
 |
 +-> worker_attach_to_pool
```

### unbound worker_pool

大部分的 work 都是通过 normal worker_pool 来执行的 ( 例如通过 schedule_work()、schedule_work_on()
压入到系统 workqueue(system_wq) 中的 work)，最后都是通过 normal worker_pool 中的 worker 来执行的。
这些 worker是和某个CPU 绑定的，work 一旦被worker开始执行，都是一直运行到某个CPU 上的不会切换 CPU。

unbound worker_pool 相对应的意思，就是 worker 可以在多个 CPU 上调度的。但是他其实也是绑定的，
只不过它绑定的单位不是 CPU 而是 node。所谓的 node 是对 NUMA(Non Uniform Memory Access Architecture)
系统来说的，NUMA 可能存在多个 node，每个 node 可能包含一个或者多个 CPU。

unbound worker_pool 对应内核线程 (worker_thread()) 的命名规则是这样的：

```
	if (pool->cpu >= 0) // normal worker_pool
		snprintf(id_buf, sizeof(id_buf), "%d:%d%s", pool->cpu, id,
			 pool->attrs->nice < 0  ? "H" : "");
	else // unbound worker_pool
		snprintf(id_buf, sizeof(id_buf), "u%d:%d", pool->id, id);
	worker->task = kthread_create_on_node(worker_thread, worker, pool->node,
					      "kworker/%s", id_buf);
```

类似名字是 unbound worker_pool：

```
sagit:/ $ ps | grep kworker/u
root      82    2     0      0              0 0000000000 D kworker/u16:1
root      89    2     0      0              0 0000000000 S kworker/u16:2
root      358   2     0      0              0 0000000000 S kworker/u16:8
root      359   2     0      0              0 0000000000 S kworker/u16:9
root      369   2     0      0              0 0000000000 S kworker/u17:0
root      1054  2     0      0              0 0000000000 S kworker/u17:1
root      12344 2     0      0              0 0000000000 S kworker/u16:4
root      12510 2     0      0              0 0000000000 S kworker/u16:6
root      12601 2     0      0              0 0000000000 S kworker/u16:0
root      12627 2     0      0              0 0000000000 S kworker/u16:3
```

unbound worker_pool 也分成两类：

#### unbound std_wq

每个 node 对应一个 worker_pool，多个 node 就对应多个 worker_pool;

https://github.com/novelinux/linux-4.x.y/tree/master/kernel/workqueue.c/res/wq_unbound_std_wq.png

对应的拓扑图如下：

https://github.com/novelinux/linux-4.x.y/tree/master/kernel/workqueue.c/res/wq_unbound_std_wq_topology.png

#### unbound ordered_wq

所有 node 对应一个 default worker_pool；

https://github.com/novelinux/linux-4.x.y/tree/master/kernel/workqueue.c/res/wq_unbound_ordered_wq.png

对应的拓扑图如下：

https://github.com/novelinux/linux-4.x.y/tree/master/kernel/workqueue.c/res/wq_unbound_ordered_wq_topology.png

unbound worker_pool 详细的创建过程代码分析：

```
/* PL: hash of all unbound pools keyed by pool->attrs */
static DEFINE_HASHTABLE(unbound_pool_hash, UNBOUND_POOL_HASH_ORDER);

/* I: attributes used when instantiating standard unbound pools on demand */
static struct workqueue_attrs *unbound_std_wq_attrs[NR_STD_WORKER_POOLS];

/* I: attributes used when instantiating ordered pools on demand */
static struct workqueue_attrs *ordered_wq_attrs[NR_STD_WORKER_POOLS];
 .
 .
 .
workqueue_init_early
 |
for NR_STD_WORKER_POOLS
 |
 +-> unbound_std_wq_attrs[i] = alloc_workqueue_attrs
 |
 +-> ordered_wq_attrs[i] = alloc_workqueue_attrs
 .
 .
workqueue_init
 |
hash_for_each( unbound_pool_hash )
 |
create_worker
 |
 +-> worker = alloc_worker
 |
 +-> worker->task = kthread_create_on_node
 |
 +-> worker_attach_to_pool
```

## worker

每个 worker 对应一个worker_thread() 内核线程，一个 worker_pool 对应一个或者多个 worker。
多个 worker 从同一个链表中 worker_pool->worklist 获取 work 进行处理。

### struct worker

https://github.com/novelinux/linux-4.x.y/tree/master/kernel/workqueue_internal.h/worker.md

处理 work 的过程主要在 worker_thread() -> process_one_work() 中处理，我们具体看看代码的实现过程。

```
```

###  worker_pool 动态管理 worker

worker_pool 怎么来动态增减 worker，这部分的算法是 CMWQ 的核心。其思想如下：

* worker_pool 中的 worker 有 3 种状态：idle、running、suspend；
* 如果 worker_pool 中有 work 需要处理，保持至少一个 running worker 来处理；
* running worker 在处理 work 的过程中进入了阻塞 suspend 状态，为了保持其他 work 的执行，
  需要唤醒新的 idle worker 来处理 work；
* 如果有 work 需要执行且 running worker 大于 1 个，会让多余的 running worker 进入 idle 状态；
* 如果没有 work 需要执行，会让所有 worker 进入 idle 状态；
* 如果创建的 worker 过多，destroy_worker在300s(IDLE_WORKER_TIMEOUT) 时间内没有再次运行的 idle worker。

https://github.com/novelinux/linux-4.x.y/tree/master/kernel/workqueue.c/res/wq_worker_status_machine.png

## workqueue

workqueue 就是存放一组 work 的集合，基本可以分为两类：

* 一类系统创建的 workqueue;
* 一类是用户自己创建的 workqueue。

不论是系统还是用户的 workqueue，如果没有指定 WQ_UNBOUND，默认都是和 normal worker_pool 绑定。

### struct workqueue_struct

https://github.com/novelinux/linux-4.x.y/tree/master/kernel/workqueue.c/workqueue_struct.md

### alloc_workqueue

系统在初始化时创建了一批默认的 workqueue：system_wq、system_highpri_wq、system_long_wq、
system_unbound_wq、system_freezable_wq、system_power_efficient_wq、
system_freezable_power_efficient_wq。 像 system_wq，就是 schedule_work() 默认使用的。

```
alloc_workqueue
 |
__alloc_workqueue_key
 |
 +-> wq = kzalloc( struct workqueue_struct)
 |
 +-> **alloc_and_link_pwqs(wq)**
 |
 +-> rescuer_thread
```

### alloc_and_link_pwqs

```
alloc_and_link_pwqs(wq)
 |
 +-> ! (wq->flags & WQ_UNBOUND)
 |   |
 |   +-> wq->cpu_pwqs = alloc_percpu(struct pool_workqueue)
 |   |
 |   +-> for_each_possible_cpu
 |       |
 |       +-> pwq = per_cpu_ptr(wq->cpu_pwqs, cpu)
 |       |
 |       +-> cpu_pools = per_cpu(cpu_worker_pools, cpu)
 |       |
 |       +-> init_pwq(pwq, wq, &cpu_pools[highpri])
 |
 apply_workqueue_attrs(wq, ordered_wq_attrs || unbound_std_wq_attrs)
 |
 apply_workqueue_attrs_locked(wq, attrs)
  |
  +-> apply_wqattrs_prepare(wq, attrs)
  |   |        ORDERED
  |   +-> ctx->dfl_pwq = alloc_unbound_pwq(wq, new_attrs)
  |   |
  |   +-> for_each_node
  |           |
  | ctx->_pwq_tbl[node] = alloc_unbound_pwq || ctx->dfl_pwq
  |   |
  |   +-> pool = **get_unbound_pool**
  |   |
  |   +-> pwq = kmem_cache_alloc_node(pwq_cache)
  |   |
  |   +-> init_pwq(pwq, wq, pool)
  |
  +-> apply_wqattrs_commit
  |
  +-> apply_wqattrs_cleanup
```

### get_unbound_pool

```
get_unbound_pool
 |
 +-> hash_for_each_possible(unbound_pool_hash)
 |
 nope, create a new one
  |
  +-> pool = kzalloc_node
  |
  +-> hash_add(unbound_pool_hash, &pool->hash_node, hash)
```

## work

描述一份待执行的工作。

## pwq (pool_workqueue)

pool_workqueue 只是一个中介角色。

详细过程见上workqueue的代码分析.

### struct pool_workqueue

https://github.com/novelinux/linux-4.x.y/tree/master/kernel/workqueue.c/pool_workqueue.md
