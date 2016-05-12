enum node_states
========================================

结点状态管理如果系统中结点多于一个，内核会维护一个位图，用以提供各个结点的状态信息。状态是用
位掩码指定的，可使用下列值：

path: include/linux/nodemask.h
```
/*
 * Bitmasks that are kept for all the nodes.
 */
enum node_states {
    N_POSSIBLE,        /* The node could become online at some point */
    N_ONLINE,          /* The node is online */
    N_NORMAL_MEMORY,   /* The node has regular memory */
#ifdef CONFIG_HIGHMEM
    N_HIGH_MEMORY,     /* The node has regular or high memory */
#else
    N_HIGH_MEMORY = N_NORMAL_MEMORY,
#endif
#ifdef CONFIG_MOVABLE_NODE
    N_MEMORY,          /* The node has memory(regular, high, movable) */
#else
    N_MEMORY = N_HIGH_MEMORY,
#endif
    N_CPU,             /* The node has one or more cpus */
    NR_NODE_STATES
};

/*
 * The following particular system nodemasks and operations
 * on them manage all possible and online nodes.
 */

extern nodemask_t node_states[NR_NODE_STATES];
```

状态N_POSSIBLE、N_ONLINE和N_CPU用于CPU和内存的热插拔。对内存管理有必要的标志是
N_HIGH_MEMORY和N_NORMAL_MEMORY。如果结点有普通或高端内存则使用N_HIGH_MEMORY，
仅当结点没有高端内存才设置N_NORMAL_MEMORY。
