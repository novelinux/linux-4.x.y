init_nsproxy
========================================

path: kernel/nsproxy.c
```
struct nsproxy init_nsproxy = {
    .count            = ATOMIC_INIT(1),
    .uts_ns            = &init_uts_ns,
#if defined(CONFIG_POSIX_MQUEUE) || defined(CONFIG_SYSVIPC)
    .ipc_ns            = &init_ipc_ns,
#endif
    .mnt_ns            = NULL,
    .pid_ns_for_children    = &init_pid_ns,
#ifdef CONFIG_NET
    .net_ns            = &init_net,
#endif
};
```