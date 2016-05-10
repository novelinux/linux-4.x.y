node_states
========================================

path: mm/page_alloc.c
```
/*
 * Array of node states.
 */
nodemask_t node_states[NR_NODE_STATES] __read_mostly = {
       [N_POSSIBLE] = NODE_MASK_ALL,
       [N_ONLINE] = { { [0] = 1UL } },
#ifndef CONFIG_NUMA
       [N_NORMAL_MEMORY] = { { [0] = 1UL } },
#ifdef CONFIG_HIGHMEM
       [N_HIGH_MEMORY] = { { [0] = 1UL } },
#endif
#ifdef CONFIG_MOVABLE_NODE
       [N_MEMORY] = { { [0] = 1UL } },
#endif
       [N_CPU] = { { [0] = 1UL } },
#endif  /* NUMA */
};
EXPORT_SYMBOL(node_states);
```

nodemask_t
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/nodemask.h/nodemask_t.md
