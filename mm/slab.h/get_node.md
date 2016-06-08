get_node
========================================

path: mm/slab.h
```
static inline struct kmem_cache_node *get_node(struct kmem_cache *s, int node)
{
    return s->node[node];
}
```