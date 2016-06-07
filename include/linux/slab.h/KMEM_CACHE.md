KMEM_CACHE
========================================

path: include/linux/slab.h
```
/*
 * Please use this macro to create slab caches. Simply specify the
 * name of the structure and maybe some flags that are listed above.
 *
 * The alignment of the struct determines object alignment. If you
 * f.e. add ____cacheline_aligned_in_smp to the struct declaration
 * then the objects will be properly aligned in SMP configurations.
 */
#define KMEM_CACHE(__struct, __flags) kmem_cache_create(#__struct,\
        sizeof(struct __struct), __alignof__(struct __struct),\
        (__flags), NULL)
```

kmem_cache_create
----------------------------------------

https://github.com/novelinux/linux-4.x.y/blob/master/mm/slab_common.c/kmem_cache_create.md