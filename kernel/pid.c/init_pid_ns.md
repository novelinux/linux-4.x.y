init_pid_ns
========================================

path: kernel/pid.c
```
/*
 * PID-map pages start out as NULL, they get allocated upon
 * first use and are never deallocated. This way a low pid_max
 * value does not cause lots of bitmaps to be allocated, but
 * the scheme scales to up to 4 million PIDs, runtime.
 */
struct pid_namespace init_pid_ns = {
    .kref = {
        .refcount       = ATOMIC_INIT(2),
    },
    .pidmap = {
        [ 0 ... PIDMAP_ENTRIES-1] = { ATOMIC_INIT(BITS_PER_PAGE), NULL }
    },
    .last_pid = 0,
    .nr_hashed = PIDNS_HASH_ADDING,
    .level = 0,
    .child_reaper = &init_task,
    .user_ns = &init_user_ns,
    .ns.inum = PROC_PID_INIT_INO,
#ifdef CONFIG_PID_NS
    .ns.ops = &pidns_operations,
#endif
};
EXPORT_SYMBOL_GPL(init_pid_ns);
```