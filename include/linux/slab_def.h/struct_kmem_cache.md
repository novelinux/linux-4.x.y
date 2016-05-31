struct kmem_cache
========================================

除了管理性数据(如已用和空闲对象或标志寄存器的数目)，缓存结构包括两个特别重要的成员:

* 指向一个数组的指针，其中保存了各个CPU最后释放的对象。

* 每个内存结点都对应3个表头，用于组织slab的链表。第1个链表包含完全用尽的slab，
  第2个是部分空闲的slab，第3个是空闲的slab。

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/slab_def.h/res/struct_kmem_cache.jpg

缓存结构指向一个数组，其中包含了与系统CPU数目相同的数组项。每个元素都是一个指针，指向一个进一步的
结构称之为数组缓存(array cache)，其中包含了对应于特定系统CPU的管理数据（就总体来看，不是用于缓存）。
管理性数据之后的内存区包含了一个指针数组，各个数组项指向slab中未使用的对象。

为最好地利用CPU高速缓存，这些per-CPU指针是很重要的。在分配和释放对象时，采用后进先出原理
(LIFO，last infirst out）。内核假定刚释放的对象仍然处于CPU高速缓存中，会尽快再次分配它（响应
下一个分配请求）。仅当per-CPU缓存为空时，才会用slab中的空闲对象重新填充它们。这样，对象分配的体系
就形成了一个三级的层次结构，分配成本和操作对CPU高速缓存和TLB的负面影响逐级升高。

* 仍然处于CPU高速缓存中的per-CPU对象;
* 现存slab中未使用的对象;
* 刚使用伙伴系统分配的新slab中未使用的对象;

path: include/linux/slab_def.h
```
/*
 * Definitions unique to the original Linux SLAB allocator.
 */

struct kmem_cache {
    struct array_cache __percpu *cpu_cache;

/* 1) Cache tunables. Protected by slab_mutex */
    unsigned int batchcount;
    unsigned int limit;
    unsigned int shared;

    unsigned int size;
    struct reciprocal_value reciprocal_buffer_size;
/* 2) touched by every alloc & free from the backend */

    unsigned int flags;        /* constant flags */
    unsigned int num;        /* # of objs per slab */

/* 3) cache_grow/shrink */
    /* order of pgs per slab (2^n) */
    unsigned int gfporder;

    /* force GFP flags, e.g. GFP_DMA */
    gfp_t allocflags;

    size_t colour;            /* cache colouring range */
    unsigned int colour_off;    /* colour offset */
    struct kmem_cache *freelist_cache;
    unsigned int freelist_size;

    /* constructor func */
    void (*ctor)(void *obj);

/* 4) cache creation/removal */
    const char *name;
    struct list_head list;
    int refcount;
    int object_size;
    int align;

/* 5) statistics */
#ifdef CONFIG_DEBUG_SLAB
    unsigned long num_active;
    unsigned long num_allocations;
    unsigned long high_mark;
    unsigned long grown;
    unsigned long reaped;
    unsigned long errors;
    unsigned long max_freeable;
    unsigned long node_allocs;
    unsigned long node_frees;
    unsigned long node_overflow;
    atomic_t allochit;
    atomic_t allocmiss;
    atomic_t freehit;
    atomic_t freemiss;

    /*
     * If debugging is enabled, then the allocator can add additional
     * fields and/or padding to every object. size contains the total
     * object size including these internal fields, the following two
     * variables contain the offset to the user object and its size.
     */
    int obj_offset;
#endif /* CONFIG_DEBUG_SLAB */
#ifdef CONFIG_MEMCG_KMEM
    struct memcg_cache_params memcg_params;
#endif

    struct kmem_cache_node *node[MAX_NUMNODES];
};
```