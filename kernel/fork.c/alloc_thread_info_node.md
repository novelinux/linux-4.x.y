alloc_thread_info_node
========================================

THREAD_SIZE
----------------------------------------

### ARM

https://github.com/novelinux/linux-4.x.y/tree/master/arch/arm/include/asm/thread_info.h/THREAD_SIZE.md

THREAD_SIZE >= PAGE_SIZE
----------------------------------------

path: kernel/fork.c
```
#ifndef CONFIG_ARCH_THREAD_INFO_ALLOCATOR

/*
 * Allocate pages if THREAD_SIZE is >= PAGE_SIZE, otherwise use a
 * kmemcache based allocator.
 */
# if THREAD_SIZE >= PAGE_SIZE
static struct thread_info *alloc_thread_info_node(struct task_struct *tsk,
                          int node)
{
    struct page *page = alloc_kmem_pages_node(node, THREADINFO_GFP,
                          THREAD_SIZE_ORDER);

    return page ? page_address(page) : NULL;
}

static inline void free_thread_info(struct thread_info *ti)
{
    free_kmem_pages((unsigned long)ti, THREAD_SIZE_ORDER);
}
```

### alloc_kmem_pages_node

https://github.com/novelinux/linux-4.x.y/tree/master/mm/page_alloc.c/alloc_kmem_pages_node.md

THREAD_SIZE < PAGE_SIZE
----------------------------------------

```
# else
static struct kmem_cache *thread_info_cache;

static struct thread_info *alloc_thread_info_node(struct task_struct *tsk,
                          int node)
{
    return kmem_cache_alloc_node(thread_info_cache, THREADINFO_GFP, node);
}

static void free_thread_info(struct thread_info *ti)
{
    kmem_cache_free(thread_info_cache, ti);
}

void thread_info_cache_init(void)
{
    thread_info_cache = kmem_cache_create("thread_info", THREAD_SIZE,
                          THREAD_SIZE, 0, NULL);
    BUG_ON(thread_info_cache == NULL);
}
# endif
#endif
```

### kmem_cache_alloc_node

https://github.com/novelinux/linux-4.x.y/tree/master/include/linux/slab.h/kmem_cache_alloc_node.md
