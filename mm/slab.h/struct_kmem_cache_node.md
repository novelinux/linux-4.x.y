struct kmem_cache_node
========================================

list_lock
----------------------------------------

path: mm/slab.h
```
#ifndef CONFIG_SLOB
/*
 * The slab lists for all objects.
 */
struct kmem_cache_node {
       spinlock_t list_lock;
```

slabs_partial
----------------------------------------

```
#ifdef CONFIG_SLAB
       struct list_head slabs_partial;  /* partial list first, better asm code */
```

slabs_full
----------------------------------------

```
       struct list_head slabs_full;
```

slabs_free
----------------------------------------

```
       struct list_head slabs_free;
```

free_objects表示slabs_partial和slabs_free的所有slab中空闲对象的总数。

free_objects
----------------------------------------

```
       unsigned long free_objects;
```

free_limit
----------------------------------------

```
       unsigned int free_limit;
```

free_limit指定了所有slab上容许未使用对象的最大数目。

colour_next
----------------------------------------

```
       unsigned int colour_next;        /* Per-node cache coloring */
```

colour_next则是内核建立的下一个slab的颜色.

这也是用于NUMA计算机，UMA系统可以将colour_next保存在struct kmem_cache中。但将下一个颜色
放置在特定于结点的结构中，可以对同一结点上添加的slab顺序着色，对本地的CPU高速缓存有好处。
实例——如果有5种可能的颜色(0, 1, 2, 3, 4)，而偏移量单位是8字节，内核可以使用下列偏移量值:
0×8= 0，1×8 = 8，2×8 = 16，3×8 = 24，4×8 = 32字节。

shared
----------------------------------------

```
       struct array_cache *shared;      /* shared per node */
```

结点内共享.

alien
----------------------------------------

```
       struct alien_cache **alien;      /* on other nodes */
```

next_reap
----------------------------------------

```
       unsigned long next_reap;         /* updated without locking */
```

next_reap定义了内核在两次尝试收缩缓存之间，必须经过的时间间隔。其想法是防止由于频繁的缓存
收缩和增长操作而降低系统性能，这种操作可能在某些系统负荷下发生。该技术只在NUMA系统上使用，

free_touched
----------------------------------------

```
       int free_touched;                   /* updated without locking */
#endif
```

free_touched表示缓存是否是活动的。在从缓存获取一个对象时，内核将该变量的值设置为1。
在缓存收缩时，该值重置为0。但内核只有在free_touched预先设置为0时，才会收缩缓存。
因为1表示内核的另一部分刚从该缓存获取对象，此时收缩是不合适的。该变量将应用到整个缓存，
因而不同于per-CPU变量touched。

nr_partial
----------------------------------------

```
#ifdef CONFIG_SLUB
       unsigned long nr_partial;
       struct list_head partial;
#ifdef CONFIG_SLUB_DEBUG
       atomic_long_t nr_slabs;
       atomic_long_t total_objects;
       struct list_head full;
#endif
#endif

};

static inline struct kmem_cache_node *get_node(struct kmem_cache *s, int node)
{
        return s->node[node];
}

/*
 * Iterator over all nodes. The body will be executed for each node that has
 * a kmem_cache_node structure allocated (which is true for all online nodes)
 */
#define for_each_kmem_cache_node(__s, __node, __n) \
        for (__node = 0; __node < nr_node_ids; __node++) \
             if ((__n = get_node(__s, __node)))

#endif
```