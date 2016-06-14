init_net
========================================

path: net/core/net_namespace.c
```
struct net init_net = {
    .dev_base_head = LIST_HEAD_INIT(init_net.dev_base_head),
};
EXPORT_SYMBOL(init_net);
```
