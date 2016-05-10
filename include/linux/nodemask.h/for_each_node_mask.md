for_each_node_mask
========================================

path: include/linux/nodemask.h
```
#if MAX_NUMNODES > 1
#define for_each_node_mask(node, mask)			\
	for ((node) = first_node(mask);			\
		(node) < MAX_NUMNODES;			\
		(node) = next_node((node), (mask)))
#else /* MAX_NUMNODES == 1 */
#define for_each_node_mask(node, mask)			\
	if (!nodes_empty(mask))				\
		for ((node) = 0; (node) < 1; (node)++)
#endif /* MAX_NUMNODES */
```

MAX_NUMNODES
----------------------------------------

https://github.com/leeminghao/doc-linux/tree/master/4.x.y/include/linux/numa.h/MAX_NUMNODES.md