struct page
========================================

页帧代表系统内存的最小单位，对内存中的每个页都会创建struct page的一个实例。内核程序员需要注意
保持该结构尽可能小，因为即使在中等程度的内存配置下，系统的内存同样会分解为大量的页。
例如，ARM系统的标准页长度为4 KiB，在主内存大小为384 MiB时，大约共有100 000页。就当今的标准而言，
这个容量算不上很大，但页的数目已经非常可观。

这也是为什么内核尽力保持struct page尽可能小的原因。在典型系统中，由于页的数目巨大，因此对
page结构的小改动，也可能导致保存所有page实例所需的物理内存暴涨。

页的广泛使用，增加了保持结构长度的难度：内存管理的许多部分都使用页，用于各种不同的用途。
内核的一个部分可能完全依赖于struct page提供的特定信息，而该信息对内核的另一部分可能完全无用，
该部分依赖于struct page提供的其他信息，而这部分信息对内核的其他部分也可能是完全无用的，等等。
C语言的联合很适合于该问题，尽管它未能增加struct page的清晰程度。

path: include/linux/mm_types.h
```
/*
 * Each physical page in the system has a struct page associated with
 * it to keep track of whatever it is we are using the page for at the
 * moment. Note that we have no way to track which tasks are using
 * a page, though if it is a pagecache page, rmap structures can tell us
 * who is mapping it.
 *
 * The objects in struct page are organized in double word blocks in
 * order to allows us to use atomic double word operations on portions
 * of struct page. That is currently only used by slub but the arrangement
 * allows the use of atomic double word operations on the flags/mapping
 * and lru list pointers also.
 */
struct page {
```

First double world block
----------------------------------------

### flags

flags存储了体系结构无关的标志，用于描述页的属性.

```
    /* First double word block */
    unsigned long flags;        /* Atomic flags, some possibly
                                 * updated asynchronously */
```

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/page-flags.h/enum_pageflags.md

### union

#### mapping

```
    union {
        struct address_space *mapping;    /* If low bit clear, points to
                                           * inode address_space, or NULL.
                                           * If page mapped as anonymous
                                           * memory, low bit is set, and
                                           * it points to anon_vma object:
                                           * see PAGE_MAPPING_ANON below.
                                           */
```

mapping指定了页帧所在的地址空间。index是页帧在映射内部的偏移量。地址空间是一个非常一般的概念，
例如，可以用在向内存读取文件时。地址空间用于将文件的内容（数据）与装载数据的内存区关联起来。
通过一个小技巧，mapping不仅能够保存一个指针，而且还能包含一些额外的信息，用于判断页是否属于
未关联到地址空间的某个匿名内存区。如果将mapping置为1，则该指针并不指向address_space的实例，
而是指向另一个数据结构(anon_vma)，该结构对实现匿名页的逆向映射很重要。对该指针的双重使用
是可能的，因为address_space实例总是对齐到sizeof(long)。因此在Linux支持的所有计算机上，指向
该实例的指针最低位总是0。该指针如果指向address_space实例，则可以直接使用。如果使用了技巧将
最低位设置为1，内核可使用下列操作恢复来恢复指针：

```
anon_vma = (struct anon_vma *) (mapping -PAGE_MAPPING_ANON)
```

#### s_mem

```
        void *s_mem;            /* slab first object */
    };
```

Second double world block
----------------------------------------

### union

```
    /* Second double word */
    struct {
        union {
            pgoff_t index;        /* Our offset within mapping. */
            void *freelist;        /* sl[aou]b first free object */
        };
```

### union

#### counters

```
        union {
#if defined(CONFIG_HAVE_CMPXCHG_DOUBLE) && \
    defined(CONFIG_HAVE_ALIGNED_STRUCT_PAGE)
            /* Used for cmpxchg_double in slub */
            unsigned long counters;
#else
            /*
             * Keep _count separate from slub cmpxchg_double data.
             * As the rest of the double word is protected by
             * slab_lock but _count is not.
             */
            unsigned counters;
#endif
```

#### struct

##### union

一个物理内存页能够通过多个地方的不同页表映射到虚拟地址空间，内核想要跟踪有多少地方映射了该页。
为此，struct page中有一个计数器用于计算映射的数目。如果一页用于slub分配器(将整页细分为更小部分
的一种方法），那么可以确保只有内核会使用该页，而不会有其他地方使用，因此映射计数信息就是多余的。
因此内核可以重新解释该字段，用来表示该页被细分为多少个小的内存对象使用。

* _mapcount表示在页表中有多少项指向该页。

```
            struct {
                union {
                    /*
                     * Count of ptes mapped in
                     * mms, to show when page is
                     * mapped & limit reverse map
                     * searches.
                     *
                     * Used also for tail pages
                     * refcounting instead of
                     * _count. Tail pages cannot
                     * be mapped and keeping the
                     * tail page _count zero at
                     * all times guarantees
                     * get_page_unless_zero() will
                     * never succeed on tail
                     * pages.
                     */
                    atomic_t _mapcount;

                    struct { /* SLUB */
                        unsigned inuse:16;
                        unsigned objects:15;
                        unsigned frozen:1;
                    };

                    int units;    /* SLOB */
                };
```

##### _count

_count是一个使用计数，表示内核中引用该页的次数。在其值到达0时，内核就知道page实例当前不使用，
因此可以删除。如果其值大于0，该实例决不会从内存删除。

```
                atomic_t _count;        /* Usage count, see below. */
            };
```

#### active

```
            unsigned int active;    /* SLAB */
        };
    };
```

Third double word block
----------------------------------------

### union

#### lru

lru是一个表头，用于在各种链表上维护该页，以便将页按不同类别分组，最重要的类别是活动和不活动页。

```
    /* Third double word block */
    union {

        struct list_head lru;    /* Pageout list, eg. active_list
                                  * protected by zone->lru_lock !
                                  * Can be used as a generic list
                                  * by the page owner.
                                  */
```

#### struct

```
        struct {                 /* slub per cpu partial pages */
            struct page *next;   /* Next partial slab */
#ifdef CONFIG_64BIT
            int pages;           /* Nr of partial slabs left */
            int pobjects;        /* Approximate # of objects */
#else
            short int pages;
            short int pobjects;
#endif
        };
```

#### slab_page

```
        struct slab *slab_page;    /* slab fields */
        struct rcu_head rcu_head;  /* Used by SLAB
                                    * when destroying via RCU
                                    */
        /* First tail page of compound page */
        struct {
            compound_page_dtor *compound_dtor;
            unsigned long compound_order;
        };

#if defined(CONFIG_TRANSPARENT_HUGEPAGE) && USE_SPLIT_PMD_PTLOCKS
        pgtable_t pmd_huge_pte; /* protected by page->ptl */
#endif
    };
```

### union

#### private

private是一个指向“私有”数据的指针,虚拟内存管理会忽略该数据.根据页的用途，
可以用不同的方式使用该指针,大多数情况下它用于将页与数据缓冲区关联起来.

```
    /* Remainder is not double word aligned */
    union {
        unsigned long private;        /* Mapping-private opaque data:
                                       * usually used for buffer_heads
                                       * if PagePrivate set; used for
                                       * swp_entry_t if PageSwapCache;
                                       * indicates order in the buddy
                                       * system if PG_buddy is set.
                                       */
```

#### ptl

```
#if USE_SPLIT_PTE_PTLOCKS
#if ALLOC_SPLIT_PTLOCKS
        spinlock_t *ptl;
#else
        spinlock_t ptl;
#endif
#endif
```

#### slab_cache

```
        struct kmem_cache *slab_cache;    /* SL[AU]B: Pointer to slab */
```

#### first_page

内核可以将多个毗连的页合并为较大的复合页（compoundpage）。分组中的第一个页称作首页（head page），
而所有其余各页叫做尾页（tail page）。所有尾页对应的page实例中，都将first_page设置为指向首页。

```
        struct page *first_page;          /* Compound tail pages */
    };
```

### mem_cgroup

```
#ifdef CONFIG_MEMCG
    struct mem_cgroup *mem_cgroup;
#endif
```

### virtual

virtual用于高端内存区域中的页，换言之，即无法直接映射到内核内存中的页。virtual用于存储该页的
虚拟地址。按照预处理器语句#if defined(WANT_PAGE_VIRTUAL)，只有定义了对应的宏，virtual才能成为
struct page的一部分。当前只有几个体系结构是这样，即摩托罗拉m68k、FRV和Extensa。所有其他体系结构
都采用了一种不同的方案来寻址虚拟内存页。其核心是用来查找所有高端内存页帧的散列表。处理散列表
需要一些数学运算，在前述的计算机上比较慢，因此只能选择这种直接的方法。

```
    /*
     * On machines where all RAM is mapped into kernel address space,
     * we can simply calculate the virtual address. On machines with
     * highmem some memory is mapped into kernel virtual memory
     * dynamically, so we need a place to store that address.
     * Note that this field could be 16 bits on x86 ... ;)
     *
     * Architectures with slow multiplication can define
     * WANT_PAGE_VIRTUAL in asm/page.h
     */
#if defined(WANT_PAGE_VIRTUAL)
    void *virtual;            /* Kernel virtual address (NULL if
                       not kmapped, ie. highmem) */
#endif /* WANT_PAGE_VIRTUAL */
```

### shadow

```
#ifdef CONFIG_KMEMCHECK
    /*
     * kmemcheck wants to track the status of each byte in a page; this
     * is a pointer to such a status block. NULL if not tracked.
     */
    void *shadow;
#endif
```

### _last_cpupid

```
#ifdef LAST_CPUPID_NOT_IN_PAGE_FLAGS
    int _last_cpupid;
#endif
```

CONFIG_HAVE_ALIGNED_STRUCT_PAGE
----------------------------------------

```
}
/*
 * The struct page can be forced to be double word aligned so that atomic ops
 * on double words work. The SLUB allocator can make use of such a feature.
 */
#ifdef CONFIG_HAVE_ALIGNED_STRUCT_PAGE
    __aligned(2 * sizeof(unsigned long))
#endif
;
```