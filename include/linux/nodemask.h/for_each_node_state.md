for_each_node_state
========================================

path: include/linux/nodemask.h
```
#define for_each_node_state(__node, __state) \
    for_each_node_mask((__node), node_states[__state])
```

for_each_node_mask
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/nodemask.h/for_each_node_mask.md

node_states
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/mm/page_alloc.c/node_states.md
