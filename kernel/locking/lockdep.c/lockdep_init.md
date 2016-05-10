lockdep_init
========================================

lockdep是linux内核的一个调试模块，用来检查内核互斥机制尤其是自旋锁潜在的死锁问题。
自旋锁由于是查询方式等待，不释放处理器，比一般的互斥机制更容易死锁，故引入lockdep
检查以下几种情况可能的死锁:

* 同一个进程递归地加锁同一把锁；
* 一把锁既在中断（或中断下半部）使能的情况下执行过加锁操作，又在中断（或中断下半部）里
  执行过加锁操作。这样该锁有可能在锁定时由于中断发生又试图在同一处理器上加锁；
* 几把锁形成一个闭环死锁。加锁后导致依赖图产生成闭环，这是典型的死锁现象。

path: kernel/locking/lockdep.c
```
void lockdep_init(void)
{
    int i;

    /*
     * Some architectures have their own start_kernel()
     * code which calls lockdep_init(), while we also
     * call lockdep_init() from the start_kernel() itself,
     * and we want to initialize the hashes only once:
     */
    if (lockdep_initialized)
        return;

    for (i = 0; i < CLASSHASH_SIZE; i++)
        INIT_LIST_HEAD(classhash_table + i);

    for (i = 0; i < CHAINHASH_SIZE; i++)
        INIT_LIST_HEAD(chainhash_table + i);

    lockdep_initialized = 1;
}
```