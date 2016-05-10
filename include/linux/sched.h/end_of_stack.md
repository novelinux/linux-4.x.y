end_of_stack
========================================

path: include/linux/sched.h
```
static inline unsigned long *end_of_stack(struct task_struct *p)
{
    return (unsigned long *)(task_thread_info(p) + 1);
}
```
