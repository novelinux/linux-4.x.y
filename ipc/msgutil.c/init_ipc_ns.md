init_ipc_ns
========================================

path: ipc/msgutil.c
```
/*
 * The next 2 defines are here bc this is the only file
 * compiled when either CONFIG_SYSVIPC and CONFIG_POSIX_MQUEUE
 * and not CONFIG_IPC_NS.
 */
struct ipc_namespace init_ipc_ns = {
    .count   = ATOMIC_INIT(1),
    .user_ns = &init_user_ns,
    .ns.inum = PROC_IPC_INIT_INO,
#ifdef CONFIG_IPC_NS
    .ns.ops = &ipcns_operations,
#endif
};
```