init_kmem_cache_node
========================================

path: mm/slab.c
```
/*
 * Need this for bootstrapping a per node allocator.
 */
#define NUM_INIT_LISTS (2 * MAX_NUMNODES)
static struct kmem_cache_node __initdata init_kmem_cache_node[NUM_INIT_LISTS];
```