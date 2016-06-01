struct kmem_cache
========================================

除了管理性数据(如已用和空闲对象或标志寄存器的数目)，缓存结构包括两个特别重要的成员:

* 指向一个数组的指针，其中保存了各个CPU最后释放的对象。

* 每个内存结点都对应3个表头，用于组织slab的链表。第1个链表包含完全用尽的slab，
  第2个是部分空闲的slab，第3个是空闲的slab。

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/slab_def.h/res/struct_kmem_cache.jpg

缓存结构指向一个数组，其中包含了与系统CPU数目相同的数组项。每个元素都是一个指针，指向一个进一步的
结构称之为数组缓存(array cache)，其中包含了对应于特定系统CPU的管理数据(就总体来看，不是用于缓存)。
管理性数据之后的内存区包含了一个指针数组，各个数组项指向slab中未使用的对象。

为最好地利用CPU高速缓存，这些per-CPU指针是很重要的。在分配和释放对象时，采用后进先出原理
(LIFO，last infirst out）。内核假定刚释放的对象仍然处于CPU高速缓存中，会尽快再次分配它（响应
下一个分配请求）。仅当per-CPU缓存为空时，才会用slab中的空闲对象重新填充它们。这样，对象分配的体系
就形成了一个三级的层次结构，分配成本和操作对CPU高速缓存和TLB的负面影响逐级升高。

* 仍然处于CPU高速缓存中的per-CPU对象;
* 现存slab中未使用的对象;
* 刚使用伙伴系统分配的新slab中未使用的对象;

cpu_cache
----------------------------------------

path: include/linux/slab_def.h
```
/*
 * Definitions unique to the original Linux SLAB allocator.
 */

struct kmem_cache {
    struct array_cache __percpu *cpu_cache;
```

cpu_cache是一个指向数组的指针，每个数组项都对应于系统中的一个CPU。每个数组项都包含了另一个指针，
指向array_cache结构的实例。

https://github.com/novelinux/linux-4.x.y/tree/master/mm/slab.c/struct_array_cache.md

batchcount
----------------------------------------

```
/* 1) Cache tunables. Protected by slab_mutex */
    unsigned int batchcount;
```

batchcount指定了在per-CPU列表为空的情况下，从缓存的slab中获取对象的数目。它还表示在缓存增长时
分配的对象数目。

limit
----------------------------------------

```
    unsigned int limit;
```

limit指定了per-CPU列表中保存的对象的最大数目。如果超出该值，内核会将batchcount个对象返回到
slab（如果接下来内核缩减缓存，则释放的内存从slab返回到伙伴系统）。

shared
----------------------------------------

```
    unsigned int shared;
```

size
----------------------------------------

```
    unsigned int size;
```

size指定了缓存中管理的对象的长度.

reciprocal_buffer_size
----------------------------------------

```
    struct reciprocal_value reciprocal_buffer_size;
```

假定内核有一个指针指向slab中的一个元素，而需要确定对应的对象索引。最容易的方法是，将指针指向的
对象地址，减去slab内存区的起始地址，然后将获得的对象偏移量，除以对象的长度。

考虑一个例子，一个slab内存区起始于内存位置100，每个对象需要5字节，上文所述的对象位于内存位置115。
对象和slab起始处之间的偏移量为115-100=15，因此对象索引是15/5=3。遗憾的是，在某些较古老的计算机上,
除法比较慢。由于乘法在这些计算机上要快得多，因此内核使用所谓的Newton-Raphson方法，这只需要
乘法和移位。尽管对我们来说，数学细节没什么趣味，但需要知道，内核可以不计算C = A/B，而是采用
C= reciprocal_divide(A, reciprocal_value(B))的方式，后者涉及的两个函数都是库程序。由于特定
slab中的对象长度是恒定的，内核可以将size的recpirocal值存储在recpirocal_buffer_size中，
该值可以在后续的除法计算中使用。

flags
----------------------------------------

```
/* 2) touched by every alloc & free from the backend */

    unsigned int flags;        /* constant flags */
```

flags是一个标志寄存器，定义缓存的全局性质。当前只有一个标志位。如果管理结构存储在slab外部，
则置位CFLGS_OFF_SLAB。

num
----------------------------------------

```
    unsigned int num;        /* # of objs per slab */
```

num保存了可以放入slab的对象的最大数目。

gfporder
----------------------------------------

```
/* 3) cache_grow/shrink */
    /* order of pgs per slab (2^n) */
    unsigned int gfporder;
```

gfporder指定了slab包含的页数目以2为底的对数，换句话说，slab包含2^gfporder页。

allocflags
----------------------------------------

```
    /* force GFP flags, e.g. GFP_DMA */
    gfp_t allocflags;
```

colour
----------------------------------------

```
    size_t colour;            /* cache colouring range */
```

colour指定了颜色的最大数目.

colour_off
----------------------------------------

```
    unsigned int colour_off;    /* colour offset */
```

colour_off是基本偏移量乘以颜色值获得的绝对偏移量。

freelist_cache
----------------------------------------

```
    struct kmem_cache *freelist_cache;
```

freelist_size
----------------------------------------

```
    unsigned int freelist_size;
```

ctor
----------------------------------------

```
    /* constructor func */
    void (*ctor)(void *obj);
```

ctor是一个指针，指向在对象创建时调用的构造函数。该方法在诸如C++和Java之类的面向对象编程语言中
为大家所熟知。以前的内核版本确实也提供了指定一个额外的析构函数的功能，但由于没有使用的缘故，
该特性已经在内核版本2.6.22开发期间撤销。

name
----------------------------------------

```
/* 4) cache creation/removal */
    const char *name;
```

name是一个字符串，包含该缓存的名称。例如，在列出/proc/slabinfo中可用的缓存时，会使用。

list
----------------------------------------

```
    struct list_head list;
```

list是一个标准的链表元素，用于将kmem_cache的所有实例保存在全局链表cache_chain上。

refcount
----------------------------------------

```
    int refcount;
```

object_size
----------------------------------------

```
    int object_size;
```

objsize是缓存中对象的长度，包括用于对齐目的的所有填充字节。

align
----------------------------------------

```
    int align;
```

statistics
----------------------------------------

```
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
```

node
----------------------------------------

```
    struct kmem_cache_node *node[MAX_NUMNODES];
};
```

node是一个数组，每个数组项对应于系统中一个可能的内存结点。每个数组项都包含struct kmem_cache_node
的一个实例，该结构中有3个slab列表（完全用尽、空闲、部分空闲）。该成员必须置于结构的末尾。尽管
它在形式上总是有MAX_NUMNODES项，但在NUMA计算机上实际可用的结点数目可能会少一些。因而该数组需要
的项数也会变少，内核在运行时对该结构分配比理论上更少的内存，就可以缩减该数组的项数。如果node
放置在该结构中间，就无法做到这一点。在UMA计算机上，这称不上问题，因为只有一个可用结点。

https://github.com/novelinux/linux-4.x.y/tree/master/mm/slab.h/struct_kmem_cache_node.md
