for_each_online_node
========================================

for_each_online_node(node)则迭代所有活动结点。

path: include/linux/nodemask.h
```
#define for_each_online_node(node) for_each_node_state(node, N_ONLINE)
```

for_each_node_state
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/nodemask.h/for_each_node_state.md

N_ONLINE
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/nodemask.h/enum_node_states.md