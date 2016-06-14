pid_nr_ns
========================================

path: kernel/pid.c
```
pid_t pid_nr_ns(struct pid *pid, struct pid_namespace *ns)
{
    struct upid *upid;
    pid_t nr = 0;

    // 因为父命名空间可以看到子命名空间中的PID，反过来却不行，内核必须确保当前命名空间的level
    // 小于或等于产生局部PID的命名空间的level。
    if (pid && ns->level <= pid->level) {
        upid = &pid->numbers[ns->level];
        if (upid->ns == ns)
            nr = upid->nr;
    }
    return nr;
}
```