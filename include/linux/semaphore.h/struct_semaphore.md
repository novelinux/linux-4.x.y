## struct semaphore {

### lock

```
	raw_spinlock_t		lock;
```

### count

count指定了可以同时处于信号量保护的临界区中进程的数目。count == 1用于大多数情况（此类信号量又名互斥信号量，因为它们用于实现互斥）。

```
	unsigned int		count;
```

### wait_list

wait_list用于实现一个队列，保存所有在该信号量上睡眠的进程的task_struct

```
	struct list_head	wait_list;
};
```