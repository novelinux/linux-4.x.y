task_thread_info
========================================

path: include/linux/sched.h
```
#define task_thread_info(task) ((struct thread_info *)(task)->stack)
```