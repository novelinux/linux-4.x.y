allocate_mm
========================================

path: kernel/fork.c
```
#define allocate_mm() (kmem_cache_alloc(mm_cachep, GFP_KERNEL))
```
