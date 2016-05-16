struct page
========================================

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
    /* First double word block */
    unsigned long flags;        /* Atomic flags, some possibly
                     * updated asynchronously */
    union {
        struct address_space *mapping;    /* If low bit clear, points to
                         * inode address_space, or NULL.
                         * If page mapped as anonymous
                         * memory, low bit is set, and
                         * it points to anon_vma object:
                         * see PAGE_MAPPING_ANON below.
                         */
        void *s_mem;            /* slab first object */
    };

    /* Second double word */
    struct {
        union {
            pgoff_t index;        /* Our offset within mapping. */
            void *freelist;        /* sl[aou]b first free object */
        };

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
                atomic_t _count;        /* Usage count, see below. */
            };
            unsigned int active;    /* SLAB */
        };
    };

    /* Third double word block */
    union {
        struct list_head lru;    /* Pageout list, eg. active_list
                     * protected by zone->lru_lock !
                     * Can be used as a generic list
                     * by the page owner.
                     */
        struct {        /* slub per cpu partial pages */
            struct page *next;    /* Next partial slab */
#ifdef CONFIG_64BIT
            int pages;    /* Nr of partial slabs left */
            int pobjects;    /* Approximate # of objects */
#else
            short int pages;
            short int pobjects;
#endif
        };

        struct slab *slab_page; /* slab fields */
        struct rcu_head rcu_head;    /* Used by SLAB
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

    /* Remainder is not double word aligned */
    union {
        unsigned long private;        /* Mapping-private opaque data:
                          * usually used for buffer_heads
                         * if PagePrivate set; used for
                         * swp_entry_t if PageSwapCache;
                         * indicates order in the buddy
                         * system if PG_buddy is set.
                         */
#if USE_SPLIT_PTE_PTLOCKS
#if ALLOC_SPLIT_PTLOCKS
        spinlock_t *ptl;
#else
        spinlock_t ptl;
#endif
#endif
        struct kmem_cache *slab_cache;    /* SL[AU]B: Pointer to slab */
        struct page *first_page;    /* Compound tail pages */
    };

#ifdef CONFIG_MEMCG
    struct mem_cgroup *mem_cgroup;
#endif

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

#ifdef CONFIG_KMEMCHECK
    /*
     * kmemcheck wants to track the status of each byte in a page; this
     * is a pointer to such a status block. NULL if not tracked.
     */
    void *shadow;
#endif

#ifdef LAST_CPUPID_NOT_IN_PAGE_FLAGS
    int _last_cpupid;
#endif
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