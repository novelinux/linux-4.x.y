arch_dup_task_struct
========================================

path: kernel/fork.c
```
int __weak arch_dup_task_struct(struct task_struct *dst,
                           struct task_struct *src)
{
    *dst = *src;
    return 0;
}
```