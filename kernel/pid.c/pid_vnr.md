pid_vnr
========================================

在获得pid实例之后，从struct pid的numbers数组中的uid信息，即可获得数字ID：

同样重要的是要注意到，内核只需要关注产生全局PID。因为全局命名空间中所有其他ID类型都会映射到PID，
因此不必生成诸如全局TGID或SID。

path: kernel/pid.c
```
pid_t pid_vnr(struct pid *pid)
{
    return pid_nr_ns(pid, current->nsproxy->pid_ns);
}
```

pid_nr_ns
----------------------------------------

pid_vnr依赖于pid_nr_ns.

https://github.com/novelinux/linux-4.x.y/tree/master/kernel/pid.c/pid_nr_ns.md
