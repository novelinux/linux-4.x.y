struct array_cache
========================================

path: mm/slab.c
```
/*
 * struct array_cache
 *
 * Purpose:
 * - LIFO ordering, to hand out cache-warm objects from _alloc
 * - reduce the number of linked list operations
 * - reduce spinlock operations
 *
 * The limit is stored in the per-cpu structure to reduce the data cache
 * footprint.
 *
 */
```

avail
----------------------------------------

```
struct array_cache {
    unsigned int avail;
```

avail保存了当前可用对象的数目。

limit
----------------------------------------

```
    unsigned int limit;
```

limit指定了per-CPU列表中保存的对象的最大数目。如果超出该值，内核会将batchcount个对象返回到
slab（如果接下来内核缩减缓存，则释放的内存从slab返回到伙伴系统）。

batchcount
----------------------------------------

```
    unsigned int batchcount;
```

batchcount指定了在per-CPU列表为空的情况下，从缓存的slab中获取对象的数目。它还表示在缓存增长时
分配的对象数目。

touched
----------------------------------------

```
    unsigned int touched;
```

在从缓存移除一个对象时，将touched设置为1，而缓存收缩时，则将touched设置为0。这使得内核能够确认
在缓存上一次收缩之后是否被访问过，也是缓存重要性的一个标志。

entry
----------------------------------------

```
    void *entry[];    /*
                       * Must have this definition in here for the proper
                       * alignment of array_cache. Also simplifies accessing
                       * the entries.
                       *
                       * Entries should not be directly dereferenced as
                       * entries belonging to slabs marked pfmemalloc will
                       * have the lower bits set SLAB_OBJ_PFMEMALLOC
                       */
};
```

最后一个成员是一个伪数组，其中并没有数组项，只是为了便于访问内存中array_cache实例之后缓存中的
各个对象而已。
