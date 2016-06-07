alloc_task_struct_node
========================================

path: kernel/fork.c
```
static struct kmem_cache *task_struct_cachep;

static inline struct task_struct *alloc_task_struct_node(int node)
{
    return kmem_cache_alloc_node(task_struct_cachep, GFP_KERNEL, node);
}
```

kmem_cache_alloc_node
----------------------------------------

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/slab.h/kmem_cache_alloc_node.md
