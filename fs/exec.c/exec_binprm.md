exec_binprm
========================================

在exec_binprm函数中调用search_binary_handler函数查找一种适当的二进制格式，
用于所要执行的特定文件. 二进制格式处理程序负责将新程序的数据加载到旧的地址空间.

Arguments
----------------------------------------

path: fs/exec.c
```
static int exec_binprm(struct linux_binprm *bprm)
{
    pid_t old_pid, old_vpid;
    int ret;

    /* Need to fetch pid before load_binary changes it */
    old_pid = current->pid;
    rcu_read_lock();
    old_vpid = task_pid_nr_ns(current, task_active_pid_ns(current->parent));
    rcu_read_unlock();
```

search_binary_handler
----------------------------------------

```
    ret = search_binary_handler(bprm);
    if (ret >= 0) {
        audit_bprm(bprm);
        trace_sched_process_exec(current, old_pid, bprm);
        ptrace_event(PTRACE_EVENT_EXEC, old_vpid);
        proc_exec_connector(current);
    }

    return ret;
}
```

https://github.com/novelinux/linux-4.x.y/tree/master/fs/exec.c/search_binary_handler.md
