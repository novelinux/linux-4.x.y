# workqueue

Workqueue 是内核里面很重要的一个机制，特别是内核驱动，一般的小型任务 (work) 都不会自己起一个线程来
处理，而是扔到 Workqueue 中处理。Workqueue 的主要工作就是用进程上下文来处理内核中大量的小任务。

所以 Workqueue 的主要设计思想：一个是并行，多个 work 不要相互阻塞；另外一个是节省资源，多个 work
尽量共享资源 ( 进程、调度、内存 )，不要造成系统过多的资源浪费。

为了实现的设计思想，workqueue 的设计实现也更新了很多版本。最新的 workqueue 实现叫做 CMWQ
(Concurrency Managed Workqueue)，也就是用更加智能的算法来实现“并行和节省”。新版本的 workqueue
创建函数改成 alloc_workqueue()，旧版本的函数 create_workqueue() 逐渐会被被废弃。

## 1.CMWQ 的几个基本概念

关于 workqueue 中几个概念都是 work 相关的数据结构非常容易混淆，大概可以这样来理解：

* work： 工作。
* workqueue： 工作的集合。workqueue 和 work 是一对多的关系。
* worker： 工人。在代码中 worker 对应一个 worker_thread() 内核线程。
* worker_pool： 工人的集合。worker_pool 和 worker 是一对多的关系。
* pwq(pool_workqueue)： 中间人 / 中介，负责建立起 workqueue 和 worker_pool 之间的关系。
  workqueue 和 pwq 是一对多的关系，pwq 和 worker_pool 是一对一的关系

https://github.com/novelinux/linux-4.x.y/tree/master/kernel/workqueue.c/res/wq_topology.png

最终的目的还是把 work( 工作 ) 传递给 worker( 工人 ) 去执行，中间的数据结构和各种关系目的是把
这件事组织的更加清晰高效。

### worker_pool

每个执行 work 的线程叫做 worker，一组 worker 的集合叫做 worker_pool。CMWQ 的精髓就在
worker_pool里面worker 的动态增减管理上 manage_workers():

https://github.com/novelinux/system_calls/blob/master/fs/ext4-write.md

CMWQ 对 worker_pool 分成两类：

* normal worker_pool: 给通用的 workqueue 使用；
* unbound worker_pool: 给 WQ_UNBOUND 类型的的 workqueue 使；

#### 1.1.1 normal worker_pool

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

https://github.com/novelinux/linux-4.x.y/tree/master/kernel/workqueue.c/res/wq_normal_worker_pool.png

对应的拓扑图如下：

https://github.com/novelinux/linux-4.x.y/tree/master/kernel/workqueue.c/res/wq_normal_wq_topology.png

normal worker_pool 详细的创建过程代码分析：

```
```