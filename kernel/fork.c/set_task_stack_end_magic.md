set_task_stack_end_magic
========================================

在tsk指向进程的内核栈的结束位置写入一个STACK_END_MAGIC(0x57AC6E9D)用于检测内核栈是否溢出。

path: kernel/fork.c
```
void set_task_stack_end_magic(struct task_struct *tsk)
{
    unsigned long *stackend;

    stackend = end_of_stack(tsk);

    *stackend = STACK_END_MAGIC;    /* for overflow detection */
}
```

end_of_stack
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/sched.h/end_of_stack.md