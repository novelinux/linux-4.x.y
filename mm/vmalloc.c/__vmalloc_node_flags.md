__vmalloc_node_flags
========================================

path: mm/vmalloc.c
```
static inline void *__vmalloc_node_flags(unsigned long size,
                    int node, gfp_t flags)
{
    return __vmalloc_node(size, 1, flags, PAGE_KERNEL,
                    node, __builtin_return_address(0));
}
```

__vmalloc_node
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/mm/vmalloc.c/__vmalloc_node.md
